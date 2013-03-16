HOOK_TABLE_HEAD_OBJECT	struct
	lpDispatch	dd	?
	hHeap		dd	?
	dwACP		dd	?
HOOK_TABLE_HEAD_OBJECT	ends

HOOK_TABLE_BEGIN macro	_Laber:LABEL,_Dispatch:=<?>
		local	table,szFile,dllFile,lpDispatch
		table		CatStr	<TABLE_>,<_Laber>
		szFile		CatStr	<sz>,<_Laber>
		dllFile		CatStr	<_Laber>,<.dll>
		lpDispatch	CatStr	<lp>,<_Laber>,<Dispatch>

%table		equ	this byte
ifidn	<%_Dispatch>,<?>
_Dispatch	proto
endif
lpDispatch	dd	_Dispatch
		dd	?
		dd	?

szFile		db	@CatStr(<!'>,<%dllFile>,<!'>),0
		endm

HOOK_TABLE_OBJECT	struct
	hookFunction	dd	?
	lpFunction	dd	?
	szFunction	db	?
HOOK_TABLE_OBJECT	ends

HOOK_TABLE	macro	_Laber:LABEL,_Arg:=<0>
		local	protoFunction,apiFunction,hookFunction,myFunction,lpFunction,szFunction,count,protoDefine,protoDefineTemp
		protoFunction	CatStr	<proto>,@SubStr(<_Laber>,2,@SizeStr(<_Laber>)-2)
		apiFunction	CatStr	<api>,@SubStr(<_Laber>,2,@SizeStr(<_Laber>)-2)
		hookFunction	CatStr	<hook>,@SubStr(<_Laber>,2,@SizeStr(<_Laber>)-2)
		MyFunction	CatStr	<My>,@SubStr(<_Laber>,2,@SizeStr(<_Laber>)-2)
		lpFunction	CatStr	<lp>,@SubStr(<_Laber>,2,@SizeStr(<_Laber>)-2)
		szFunction	CatStr	<sz>,@SubStr(<_Laber>,2,@SizeStr(<_Laber>)-2)

		count	textequ	%_Arg
		if	count ne 0
			protoDefine	textequ	<:dword>
			count	textequ	%count-1
			repeat	count
				protoDefineTemp	textequ	@CatStr(<protoDefine>,<,:dword>)
				protoDefine	textequ	protoDefineTemp
				count	textequ	%count-1
			endm
		else
			protoDefine	textequ	<>
		endif
protoFunction	typedef	proto	protoDefine
apiFunction	typedef	ptr	protoFunction
hookFunction	dd	offset	MyFunction
lpFunction	apiFunction	?
szFunction	db	@CatStr(<!'>,@SubStr(<_Laber>,2,@SizeStr(<_Laber>)-2),<!'>),0
		endm
		
HOOK_TABLE_END	macro
		dd	?
		endm

USE_HOOK_DISPATCHER	equ	1
		.const
bOriginalCode	db	90h,90h,90h,90h,90h,8Bh,0FFh
		.code
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_HotPatch	proc	uses ebx edi esi,_hModule,_lpszProc,_lplpOri,_lpNew,_dwFlags
		local	@lpOldProc
		local	@OldProtect

;********************************************************************
;�������
;********************************************************************
		.if	!(_hModule && _lpszProc && _lpNew)
			mov	eax,ERROR_INVALID_ADDRESS
			ret
		.endif
;********************************************************************
;��ú�����ַ
;********************************************************************
		invoke	GetProcAddress,_hModule,_lpszProc
		.if	!eax
			mov	eax,ERROR_INVALID_FUNCTION
			ret
		.else
			mov	@lpOldProc,eax
			mov	ebx,_lplpOri
			mov	[ebx],eax		;����ʱ������������һ��,����[ebp+4]��Ҫ׷��2���жԱ�
			add	dword ptr [ebx],2	;�ƹ�����ͷ����Near Jump
		.endif
;********************************************************************
;�ж��Ƿ����Hot-Patching
;
;C2 XXXX	retn	XXXX		Addr-8
;90		nop			Addr-5
;90		nop
;90		nop
;90		nop
;90		nop
;8BFF		mov	edi,edi		Addr
;55		push	ebp		Addr+1
;8BEC		mov	ebp,esp		Addr+3
;********************************************************************
;bOriginalCode	db	90h,90h,90h,90h,90h,8Bh,0FFh
comment	*
		mov	eax,@lpOldProc
		lea	esi,[eax-5]
		mov	edi,offset bOriginalCode
		mov	ecx,sizeof bOriginalCode
		cld
		repe	cmpsb
		.if	!ZERO?
			mov	eax,ERROR_NOT_SUPPORTED
			ret
		.endif
	*
;********************************************************************
;�޸ķ�ҳ��������:R E->RWE
;********************************************************************
		mov	eax,@lpOldProc
		lea	edi,[eax-5]
		invoke	VirtualProtect,edi,7,PAGE_EXECUTE_READWRITE,addr @OldProtect
		.if	!eax
			mov	eax,ERROR_ACCESS_DENIED
			ret
		.endif
;********************************************************************
;д��Զ����ת
;bJmpFar	db	0E9h
;bCallNear	db	0E8h
;********************************************************************
		.if	_dwFlags == USE_HOOK_DISPATCHER
			mov	eax,0E8h
		.else
			mov	eax,0E9h
		.endif
		cld
		stosb
;********************************************************************
;����Jmp��ƫ��
;********************************************************************
		mov	eax,_lpNew
		sub	eax,edi
		sub	eax,4
		cld
		stosd
;********************************************************************
;д�����ת
;bJmpShort		db	0EBh,0F9h
;********************************************************************
		mov	word ptr [edi],0F9EBh
;********************************************************************
;�ָ���ҳ��������:RWE->R E
;********************************************************************
		mov	eax,@lpOldProc
		lea	edi,[eax-5]
		mov	ebx,@OldProtect
		invoke	VirtualProtect,edi,7,ebx,addr @OldProtect
		.if	!eax
			mov	eax,ERROR_CALL_NOT_IMPLEMENTED
			ret
		.endif

		mov	eax,ERROR_SUCCESS
		ret

_HotPatch	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_RemoveHotPatch	proc	uses ebx edi esi,_hModule,_lpszProc
		local	@lpOldProc
		local	@OldProtect

;********************************************************************
;�������
;********************************************************************
		.if	!(_hModule && _lpszProc)
			mov	eax,ERROR_INVALID_ADDRESS
			ret
		.endif
;********************************************************************
;��ú�����ַ
;********************************************************************
		invoke	GetProcAddress,_hModule,_lpszProc
		.if	!eax
			mov	eax,ERROR_INVALID_FUNCTION
			ret
		.else
			mov	@lpOldProc,eax
		.endif
;********************************************************************
;�޸ķ�ҳ��������:R E->RWE
;********************************************************************
		invoke	VirtualProtect,@lpOldProc,2,PAGE_EXECUTE_READWRITE,addr @OldProtect
		.if	!eax
			mov	eax,ERROR_ACCESS_DENIED
			ret
		.endif
;********************************************************************
;�⹳
;********************************************************************
		mov	ebx,@lpOldProc
		mov	word ptr [ebx],0FF8Bh	;mov	edi,edi
;********************************************************************
;�ָ���ҳ��������:RWE->R E
;********************************************************************
		mov	edx,@OldProtect
		invoke	VirtualProtect,@lpOldProc,2,edx,addr @OldProtect
		.if	!eax
			mov	eax,ERROR_CALL_NOT_IMPLEMENTED
			ret
		.endif

		mov	eax,ERROR_SUCCESS
		ret

_RemoveHotPatch	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_TableHook	proc	uses ebx edi esi _lpTable
		local	@hModule,@lpDispatch

		mov	edi,_lpTable
		add	edi,sizeof HOOK_TABLE_HEAD_OBJECT	;Dll Name
		invoke	LoadLibrary,edi
		mov	@hModule,eax

		mov	edi,_lpTable
		assume	edi:ptr HOOK_TABLE_HEAD_OBJECT
		.if	![edi].lpDispatch
			add	edi,sizeof HOOK_TABLE_HEAD_OBJECT
			xor	eax,eax
			mov	ecx,-1
			cld
			repnz	scasb

			assume	edi:ptr HOOK_TABLE_OBJECT
			.while	[edi].hookFunction
				;invoke	_HotPatch,@hModule,offset szMessageBoxA,offset lpMessageBoxA,_MessageBoxA,NULL
				push	NULL
				push	[edi].hookFunction	;_MessageBoxA
				lea	eax,[edi].lpFunction
				push	eax			;lpMessageBoxA
				lea	eax,[edi].szFunction
				push	eax			;offset szMessageBoxA
				push	@hModule
				call	_HotPatch
				.if	eax !=	ERROR_SUCCESS
					pushad
					invoke	MessageBox,0,addr [edi].szFunction,0,0
					popad
				.endif
				
				add	edi,sizeof HOOK_TABLE_OBJECT - sizeof HOOK_TABLE_OBJECT.szFunction
				xor	eax,eax
				mov	ecx,-1
				cld
				repnz	scasb
			.endw
		.else
			assume	edi:ptr HOOK_TABLE_HEAD_OBJECT
			push	[edi].lpDispatch
			pop	@lpDispatch
			
			add	edi,sizeof HOOK_TABLE_HEAD_OBJECT
			xor	eax,eax
			mov	ecx,-1
			cld
			repnz	scasb
			
			assume	edi:ptr HOOK_TABLE_OBJECT
			.while	[edi].hookFunction
				;invoke	_HotPatch,@hModule,offset szMessageBoxA,offset lpMessageBoxA,_Dispatch,USE_HOOK_DISPATCHER
				push	USE_HOOK_DISPATCHER
				push	@lpDispatch	;_Dispatch
				lea	eax,[edi].lpFunction
				push	eax			;lpMessageBoxA
				lea	eax,[edi].szFunction
				push	eax			;offset szMessageBoxA
				push	@hModule
				call	_HotPatch
				.if	eax !=	ERROR_SUCCESS
					pushad
					invoke	MessageBox,0,addr [edi].szFunction,0,0
					popad
				.endif
				
				add	edi,sizeof HOOK_TABLE_OBJECT - sizeof HOOK_TABLE_OBJECT.szFunction
				xor	eax,eax
				mov	ecx,-1
				cld
				repnz	scasb
			.endw
		.endif

		mov	edi,_lpTable		;��ʼ��
		assume	edi:ptr HOOK_TABLE_HEAD_OBJECT
		invoke	HeapCreate,0,0,0
		mov	[edi].hHeap,eax
		mov	[edi].dwACP,CP_SHIFT_JIS
		
		assume	edi:nothing
		
		ret
		
_TableHook	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_Dispatch2	proc
; ��ջʾ��	ebp=����ʱ��esp
;[ebp]		ԭ����EBP
;[ebp+4]	Hook����ѹ��ĺ�����ַ
;[ebp+8]	ԭ���õ�ַ
;[ebp+12]	ԭ���õĵ�һ������
;[ebp+16]	ԭ���õĵڶ�������
;[ebp+20]	ԭ���õĵ���������
;[ebp+24]	ԭ���õĵ��ĸ�����
		
		push	ebp
		mov	ebp,esp
		push	esi
		push	edi
		push	ebx
		
		;push	_P4
		push	[ebp+24]
		push	0
		push	[ebp+16]
		;push	_P1
		push	[ebp+12]
		;call	lpMessageBoxExA
		
		pop	ebx
		pop	edi
		pop	esi
		mov	esp,ebp
		pop	ebp
		add	esp,4+4+4*4	;Hook���õ�ַ+ԭ���õ�ַ+����
		push	[esp-4-4*4]	;ѹ��ԭ���õ�ַ
		ret
_Dispatch2	endp