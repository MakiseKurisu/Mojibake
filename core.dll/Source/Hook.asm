		.const
bOriginalCode	db	90h,90h,90h,90h,90h,8Bh,0FFh
		.code
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_CodeLoader	proc
		
		jmp	stHookTable.lpDispatch
_CodeLoader	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_DefaultDispatch	proc
		
		add	dword ptr [esp],2
		ret
_DefaultDispatch	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_HookDispatch	proc
		add	dword ptr [esp],2	;��������ֵ
		push	ebp
		mov	ebp,esp
		sub	esp,4	;����һ���ֲ�����
		pushad
		
		mov	edi,offset stHookTable
		add	edi,sizeof HOOK_TABLE_HEAD_OBJECT
		assume	edi:ptr HOOK_TABLE_OBJECT
		.while	[edi].lpNewFunction
			mov	eax,[edi].lpNewFunction
			mov	dword ptr [ebp-4],eax	;�����Ӧ�ĺ���
			
			mov	eax,[edi].lpOldFunction
			.if	eax == dword ptr [ebp+4]
				popad
				;add	esp,4
				mov	esp,ebp
				pop	ebp
				
				add	esp,4
				jmp	dword ptr [esp-12]	
				;[esp]=Call API�ķ��ص�ַ
				;[esp-4]=Call _Dispatch�ķ��ص�ַ
				;[esp-8]=ebp
				;[esp-12]=local
			.endif
			add	edi,sizeof HOOK_TABLE_OBJECT
		.endw
		assume	edi:nothing

		;û�ҵ�������ԭ����
		popad
		;add	esp,4
		mov	esp,ebp
		pop	ebp
		
		add	esp,4
		jmp	dword ptr [esp-4]
		;[esp]=Call API�ķ��ص�ַ
		;[esp-4]=Call _Dispatch�ķ��ص�ַ
_HookDispatch	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_HotPatch	proc	uses ebx edi esi,_lpstHook
		local	@lpOldProc
		local	@OldProtect

;********************************************************************
;�������
;********************************************************************
		.if	!(_lpstHook)
			mov	eax,ERROR_INVALID_ADDRESS
			ret
		.endif
		mov	ebx,_lpstHook
		assume	ebx:ptr HOOK_TABLE_OBJECT
;********************************************************************
;��ú�����ַ
;********************************************************************
		invoke	GetModuleHandle,[ebx].lpszModule
		invoke	GetProcAddress,eax,[ebx].lpszFunction
		.if	!eax
			mov	eax,ERROR_INVALID_FUNCTION
			ret
		.else
			mov	@lpOldProc,eax
			add	eax,2				;����ʱ��������һ��,����[ebp+4]��Ҫ׷��2���жԱ�
			mov	[ebx].lpOldFunction,eax		;�ƹ�����ͷ����Near Jump	
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
		mov	eax,@lpOldProc
		lea	esi,[eax-5]
		mov	edi,offset bOriginalCode
		mov	ecx,sizeof bOriginalCode
		cld
		repe	cmpsb
		.if	!ZERO?
			;invoke	MessageBox,0,[ebx].lpszFunction,[ebx].lpszModule,0
		.endif
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
		cld
		mov	eax,0E8h
		stosb
;********************************************************************
;����Jmp��ƫ��
;********************************************************************
		mov	eax,_CodeLoader
		sub	eax,edi
		sub	eax,4
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
		invoke	VirtualProtect,edi,7,@OldProtect,addr @OldProtect
		.if	!eax
			mov	eax,ERROR_CALL_NOT_IMPLEMENTED
			ret
		.endif

		mov	eax,ERROR_SUCCESS
		ret

_HotPatch	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_SetHook	proc	uses ebx edi esi _lpTable
		local	@lpDispatch
		
		mov	edi,_lpTable
		assume	edi:ptr HOOK_TABLE_HEAD_OBJECT
		.if	[edi].lpDispatch
			push	[edi].lpDispatch
			pop	@lpDispatch
		.else
			mov	@lpDispatch,_DefaultDispatch
		.endif
		mov	[edi].lpDispatch,_DefaultDispatch
		
		add	edi,sizeof HOOK_TABLE_HEAD_OBJECT
		assume	edi:ptr HOOK_TABLE_OBJECT
		.while	[edi].lpNewFunction
			invoke	_HotPatch,edi			
			add	edi,sizeof HOOK_TABLE_OBJECT
		.endw

		mov	edi,_lpTable
		assume	edi:ptr HOOK_TABLE_HEAD_OBJECT
		push	@lpDispatch
		pop	[edi].lpDispatch
		assume	edi:nothing
		ret
_SetHook	endp
