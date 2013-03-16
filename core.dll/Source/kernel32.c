#define  UNICODE
#include <windows.h>
#include "..\core.h"

BOOL WINAPI NewCreateDirectoryA(
  _In_      LPCSTR lpPathName,
  _In_opt_  LPSECURITY_ATTRIBUTES lpSecurityAttributes
){
    LPVOID lpuszPathName = AnsiToUnicode(lpPathName);
    BOOL Result = CreateDirectory(lpuszPathName,lpSecurityAttributes);
    DWORD LastError = GetLastError();
    HeapFree(hHeap,0,lpuszPathName);
    SetLastError(LastError);
    return Result;
}

HANDLE WINAPI NewCreateFileA(
  _In_      LPCSTR lpFileName,
  _In_      DWORD dwDesiredAccess,
  _In_      DWORD dwShareMode,
  _In_opt_  LPSECURITY_ATTRIBUTES lpSecurityAttributes,
  _In_      DWORD dwCreationDisposition,
  _In_      DWORD dwFlagsAndAttributes,
  _In_opt_  HANDLE hTemplateFile
){
    LPVOID lpuszFileName = AnsiToUnicode(lpFileName);
    HANDLE Result = CreateFile(lpuszFileName,dwDesiredAccess,dwShareMode,lpSecurityAttributes,dwCreationDisposition,dwFlagsAndAttributes,hTemplateFile);
    DWORD LastError = GetLastError();
    HeapFree(hHeap,0,lpuszFileName);
    SetLastError(LastError);
    return Result;
}

BOOL WINAPI NewDeleteFileA(
  _In_  LPCSTR lpFileName
){
    LPVOID lpuszFileName = AnsiToUnicode(lpFileName);
    BOOL Result = DeleteFile(lpuszFileName);
    DWORD LastError = GetLastError();
    HeapFree(hHeap,0,lpuszFileName);
    SetLastError(LastError);
    return Result;
}

HANDLE WINAPI NewFindFirstFileA(
  _In_   LPCSTR lpFileName,
  _Out_  LPWIN32_FIND_DATAA lpFindFileData
){
    LPVOID lpuszFileName = AnsiToUnicode(lpFileName);
    WIN32_FIND_DATA FindFileData;
    HANDLE Result = FindFirstFile(lpuszFileName,&FindFileData);
    DWORD LastError = GetLastError();

    lpFindFileData->dwFileAttributes = FindFileData.dwFileAttributes;
    lpFindFileData->ftCreationTime = FindFileData.ftCreationTime;
    lpFindFileData->ftLastAccessTime = FindFileData.ftLastAccessTime;
    lpFindFileData->ftLastWriteTime = FindFileData.ftLastWriteTime;
    lpFindFileData->nFileSizeHigh = FindFileData.nFileSizeHigh;
    lpFindFileData->nFileSizeLow = FindFileData.nFileSizeLow;
    lpFindFileData->dwReserved0 = FindFileData.dwReserved0;
    lpFindFileData->dwReserved1 = FindFileData.dwReserved1;
    WideCharToMultiByte(NewCodePage,0,FindFileData.cFileName,-1,lpFindFileData->cFileName,sizeof(lpFindFileData->cFileName),NULL,NULL);
    WideCharToMultiByte(NewCodePage,0,FindFileData.cAlternateFileName,-1,lpFindFileData->cAlternateFileName,sizeof(lpFindFileData->cAlternateFileName),NULL,NULL);

    HeapFree(hHeap,0,lpuszFileName);
    SetLastError(LastError);
    return Result;
}

UINT WINAPI NewGetACP(void)
{
    return NewCodePage;
}

LPSTR WINAPI NewGetCommandLineA(void)   //由于这个函数直接返回指针无需释放,所以只能这么做
{
    return lpszCommandLineA;
}

DWORD WINAPI NewGetFileAttributesA(
  _In_  LPCSTR lpFileName
){
    LPVOID lpuszFileName = AnsiToUnicode(lpFileName);
    DWORD Result = GetFileAttributes(lpuszFileName);
    DWORD LastError = GetLastError();
    HeapFree(hHeap,0,lpuszFileName);
    SetLastError(LastError);
    return Result;
}

DWORD WINAPI NewGetModuleFileNameA(
  _In_opt_  HMODULE hModule,
  _Out_     LPSTR lpFilename,
  _In_      DWORD nSize
){
    LPVOID lpuszFilename = 0;
    if  (lpFilename)
        lpuszFilename = HeapAlloc(hHeap,HEAP_ZERO_MEMORY,4*nSize);
    DWORD Result = GetModuleFileName(hModule,lpuszFilename,nSize);
    DWORD LastError = GetLastError();
    WideCharToMultiByte(NewCodePage,0,lpuszFilename,-1,lpFilename,nSize,NULL,NULL);
    HeapFree(hHeap,0,lpuszFilename);
    SetLastError(LastError);
    return Result;
}

HMODULE WINAPI NewGetModuleHandleA(
  _In_opt_  LPCSTR lpModuleName
){
    LPVOID lpuszModuleName = AnsiToUnicode(lpModuleName);
    HMODULE Result = GetModuleHandle(lpuszModuleName);
    DWORD LastError = GetLastError();
    HeapFree(hHeap,0,lpuszModuleName);
    SetLastError(LastError);
    return Result;
}

DWORD WINAPI K32GetModuleFileNameExW(
  _In_      HANDLE hProcess,
  _In_opt_  HMODULE hModule,
  _Out_     LPWSTR lpFilename,
  _In_      DWORD nSize
); //补上定义

DWORD WINAPI NewK32GetModuleFileNameExA(
  _In_      HANDLE hProcess,
  _In_opt_  HMODULE hModule,
  _Out_     LPSTR lpFilename,
  _In_      DWORD nSize
){
    LPVOID lpuszFilename = 0;
    if  (lpFilename)
			lpuszFilename = HeapAlloc(hHeap,HEAP_ZERO_MEMORY,4*nSize);
    DWORD Result = K32GetModuleFileNameExW(hProcess,hModule,lpuszFilename,nSize);
    DWORD LastError = GetLastError();
    WideCharToMultiByte(NewCodePage,0,lpuszFilename,-1,lpFilename,nSize,NULL,NULL);
    HeapFree(hHeap,0,lpuszFilename);
    SetLastError(LastError);
    return Result;
}

HMODULE WINAPI NewLoadLibraryA(
  _In_  LPCSTR lpFileName
){
    LPVOID lpuszFileName = AnsiToUnicode(lpFileName);
    HMODULE Result = LoadLibrary(lpuszFileName);
    DWORD LastError = GetLastError();
    HeapFree(hHeap,0,lpuszFileName);
    SetLastError(LastError);
    return Result;
}

int WINAPI NewMultiByteToWideChar(
  _In_       UINT CodePage,
  _In_       DWORD dwFlags,
  _In_       LPCSTR lpMultiByteStr,
  _In_       int cbMultiByte,
  _Out_opt_  LPWSTR lpWideCharStr,
  _In_       int cchWideChar
){
    if  (!CodePage)
        CodePage = NewCodePage;
    return ((lpMultiByteToWideChar)stMultiByteToWideChar.lpOldFunction)(CodePage,dwFlags,lpMultiByteStr,cbMultiByte,lpWideCharStr,cchWideChar);
}

BOOL WINAPI NewSetCurrentDirectoryA(
  _In_  LPCSTR lpPathName
){
    LPVOID lpuszPathName = AnsiToUnicode(lpPathName);
    BOOL Result = SetCurrentDirectory(lpuszPathName);
    DWORD LastError = GetLastError();
    HeapFree(hHeap,0,lpuszPathName);
    SetLastError(LastError);
    return Result;
}

int WINAPI NewWideCharToMultiByte(
  _In_       UINT CodePage,
  _In_       DWORD dwFlags,
  _In_       LPCWSTR lpWideCharStr,
  _In_       int cchWideChar,
  _Out_opt_  LPSTR lpMultiByteStr,
  _In_       int cbMultiByte,
  _In_opt_   LPCSTR lpDefaultChar,
  _Out_opt_  LPBOOL lpUsedDefaultChar
){
    if  (!CodePage)
        CodePage = NewCodePage;
    return ((lpWideCharToMultiByte)stWideCharToMultiByte.lpOldFunction)(CodePage,dwFlags,lpWideCharStr,cchWideChar,lpMultiByteStr,cbMultiByte,lpDefaultChar,lpUsedDefaultChar);
}