    ;    Assembler specific instructions for 32 bit ASM code

      .486                   ; minimum processor needed for 32 bit
      .model flat, stdcall   ; FLAT memory model & STDCALL calling
      option casemap :none   ; set code to case sensitive
    
      include \masm32\include\masm32rt.inc

      ; ---------------------------------------------
      ; main include file with equates and structures
      ; ---------------------------------------------
      include \masm32\include\windows.inc
      ; -------------------------------------------------------------
      ; In MASM32, each include file created by the L2INC.EXE utility
      ; has a matching library file. If you need functions from a
      ; specific library, you use BOTH the include file and library
      ; file for that library.
      ; -------------------------------------------------------------
      include \masm32\include\user32.inc
      include \masm32\include\kernel32.inc
      include \MASM32\INCLUDE\gdi32.inc

      includelib \masm32\lib\user32.lib
      includelib \masm32\lib\kernel32.lib
      includelib \MASM32\LIB\gdi32.lib
; Macros
 
    szText MACRO Name, Text:VARARG
    LOCAL lbl
          jmp lbl
            Name db Text,0
          lbl:
    ENDM

; prototipos 

     WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
     WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
     TopXY PROTO   :DWORD,:DWORD

.data
        szDisplayName db "Paint",0
        CommandLine   dd 0
        hWnd          dd 0
        hInstance     dd 0
        buffer        db 128 dup(0)
        X             dd 0
        Y             dd 0
        opcao         db "l"


.data?

    hitpoint    POINT <>        
    hitpointEnd POINT <>

.code

start:
    invoke GetModuleHandle, NULL ; provides the instance handle
    mov    hInstance, eax
    invoke GetCommandLine        ; provides the command line address
    mov    CommandLine, eax
    invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT    
    invoke ExitProcess,eax   
; coloco aqui o procedimento WinMain para criação da janela em si

WinMain proc hInst     :DWORD,
             hPrevInst :DWORD,
             CmdLine   :DWORD,
             CmdShow   :DWORD

    LOCAL wc   :WNDCLASSEX
    LOCAL msg  :MSG

    LOCAL Wwd  :DWORD
    LOCAL Wht  :DWORD
    LOCAL Wtx  :DWORD
    LOCAL Wty  :DWORD

    szText szClassName,"Generic_Class"
; coloco aqui o procedimento de Tratamento de mensagens (core do programa)
    mov wc.cbSize,         sizeof WNDCLASSEX
    mov wc.style,          CS_HREDRAW or CS_VREDRAW \
                           or CS_BYTEALIGNWINDOW
    mov wc.lpfnWndProc,    offset WndProc      ; address of WndProc
    mov wc.cbClsExtra,     NULL
    mov wc.cbWndExtra,     NULL
    m2m wc.hInstance,      hInst               ; instance handle
    mov wc.hbrBackground,  COLOR_BTNFACE+1     ; system color
    mov wc.lpszMenuName,   NULL
    mov wc.lpszClassName,  offset szClassName  ; window class name
    ; id do icon no arquivo RC
    invoke LoadIcon,hInst, IDI_APPLICATION;  500                  ; icon ID   ; resource icon
    mov wc.hIcon,          eax
    invoke LoadCursor,NULL,IDC_ARROW         ; system cursor
    mov wc.hCursor,        eax
    mov wc.hIconSm,        0

    invoke RegisterClassEx, ADDR wc     ; register the window class

    ;================================
    ; Centre window at following size
    ;================================

   ; mov Wwd, 500
   ; mov Wht, 350

   ; invoke GetSystemMetrics,SM_CXSCREEN ; get screen width in pixels
   ; invoke TopXY,Wwd,eax
   ; mov Wtx, eax

   ; invoke GetSystemMetrics,SM_CYSCREEN ; get screen height in pixels
   ; invoke TopXY,Wht,eax
   ; mov Wty, eax

    ; ==================================
    ; Create the main application window
    ; ==================================
    invoke CreateWindowEx,WS_EX_OVERLAPPEDWINDOW, \
                          ADDR szClassName, \
                          ADDR szDisplayName,\
                          WS_OVERLAPPEDWINDOW,\
                          ;Wtx,Wty,Wwd,Wht,
                          CW_USEDEFAULT,CW_USEDEFAULT, 400, 200, \
                          NULL,NULL,\
                          hInst,NULL

    mov   hWnd,eax  ; copy return value into handle DWORD

    invoke LoadMenu,hInst,600                 ; load resource menu
    invoke SetMenu,hWnd,eax                   ; set it to main window

    invoke ShowWindow,hWnd,SW_SHOWNORMAL      ; display the window
    invoke UpdateWindow,hWnd                  ; update the display

      ;===================================
      ; Loop until PostQuitMessage is sent
      ;===================================

    StartLoop:
      invoke GetMessage,ADDR msg,NULL,0,0         ; get each message
      cmp eax, 0                                  ; exit if GetMessage()
      je ExitLoop                                 ; returns zero
      invoke TranslateMessage, ADDR msg           ; translate it
      invoke DispatchMessage,  ADDR msg           ; send it to message proc
      jmp StartLoop
    ExitLoop:

      return msg.wParam

WinMain endp

WndProc proc hWin   :DWORD,
             uMsg   :DWORD,
             wParam :DWORD,
             lParam :DWORD

    LOCAL hDC    :DWORD
    LOCAL Ps     :PAINTSTRUCT
    LOCAL hWin2  :DWORD

    .if uMsg == WM_COMMAND ; menu, botoes e etc..
       ; wParam -> codigo do menu que foi acionado
        .if wParam == 1000
            invoke SendMessage, hWin, WM_SYSCOMMAND, SC_CLOSE, NULL            
            ;mov  hWin2, 00611492h ;; indica um handle para fechar obtido pelo WinLister
            ;invoke SendMessage, hWin2, WM_SYSCOMMAND, SC_CLOSE, NULL
        .endif

        .if wParam == 1100
            mov opcao, "r"
        .endif

        .if wParam == 1200
            mov opcao, "c"
        .endif

        .if wParam == 1300
            mov opcao, "l"
        .endif
      
    .elseif uMsg == WM_LBUTTONUP
      mov eax, lParam
      and eax, 0FFFFh ; limpa a parte alta do registrado de 32 bits
      mov hitpointEnd.x, eax
      mov eax, lParam    
      shr eax, 16        ; >>    eax >> 16 =>  
      mov hitpointEnd.y, eax        
      ; gera a mensagem de WM_PAINT
      invoke InvalidateRect,hWnd,NULL,FALSE

      invoke BeginPaint,hWin,ADDR Ps
      mov hDC, eax

      ; invoke MoveToEx, hDC, 50,50,0
      invoke MoveToEx, hDC, hitpointEnd.x,hitpointEnd.y, 0
      
      .if opcao == "l"
          invoke LineTo, hDC, hitpoint.x, hitpoint.y ; tudo certo!!!
      .endif

      .if opcao == "r"
        invoke Rectangle, hDC, hitpointEnd.x, hitpoint.y, hitpoint.x, hitpointEnd.y ; tudo certo!!!
      .endif

      .if opcao == "c"
        invoke Ellipse, hDC, hitpointEnd.x, hitpoint.y, hitpoint.x, hitpointEnd.y ; tudo certo!!!
      .endif

      invoke EndPaint,hWin,ADDR Ps
      return  0
                    
    .elseif uMsg == WM_LBUTTONDOWN
        ; a coordenada x y vem junta no parametro lParam. sendo os primeiros 16bits posicao x 
        ; e os outros 16 bits a posição y
        ;
        ;             X
        ;   0x FFFF FFFF
        ;      y    
        mov eax, lParam
        and eax, 0FFFFh ; limpa a parte alta do registrado de 32 bits
        mov hitpoint.x, eax
        mov eax, lParam    
        shr eax, 16        ; >>    eax >> 16 =>  
        mov hitpoint.y, eax        
        ; gera a mensagem de WM_PAINT
        invoke InvalidateRect,hWnd,NULL,FALSE

    .elseif uMsg == WM_DESTROY
        invoke PostQuitMessage,NULL
        return 0 
                
    .endif   
    invoke DefWindowProc,hWin,uMsg,wParam,lParam 
    ret

WndProc endp

end start