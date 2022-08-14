global colorizar_asm


section .data
const_unos: db 	0xff,0xff,0xff,0xff,	0xff,0xff,0xff,0xff,	0xff,0xff,0xff,0xff,	0xff,0xff,0xff,0xff ;
filtro1: db 		0xff,0xff,0xff,0xff,	0x00,0x00,0x00,0x00,	0x00,0x00,0x00,0x00,	0x00,0x00,0x00,0x00;
cfloat: dd 1.0, 1.0, 1.0, 1.0
filtro_A:       db 0  , 0  , 0  , 255 , 0  , 0  , 0  , 0, 0, 0, 0, 0, 0, 0, 0, 0
; void colorizar_asm (
; 	unsigned char *src,
; 	unsigned char *dst,
; 	int cols,
; 	int filas,
; 	int src_row_size,
; 	int dst_row_size,
;   float alpha
; );

; Parámetros:
; 	rdi = src
; 	rsi = dst
; 	rdx = cols
; 	rcx = filas
; 	r8 = src_row_size
; 	r9 = dst_row_size
;   xmm0 = alpha

section .text

colorizar_asm:
push rbp
mov rbp, rsp
push r12
push r13
push r14
push rbx

movsxd rax, edx		;rax: w
;movdqu xmm12, xmm0
sub rcx, 2
sub rax, 2

;inc rsi				;dejo los bordes en negro
mov r10, rdi
mov r11, rsi

pxor xmm11, xmm1
pxor xmm12, xmm12
movdqu xmm8, [const_unos]	;xmm6 = ||
movdqu xmm9, [filtro1]
;***********************************************************
pshufd xmm0 , xmm0, 00000000  ; xmm0  = |***********|alpha|
movdqu xmm11, [cfloat]
addps  xmm11, xmm0				;xmm11 = | 1.0 + alpha |
movdqu xmm12, [cfloat]		
subps xmm12, xmm0				;xmm12 = | 1.0 - alpha	|
psrldq xmm11, 12
psrldq xmm12, 12 
pxor xmm7, xmm7 

ciclo_filas:
	cmp rcx, 0
	je fin
	mov rdi, r10
	mov rsi, r11
	mov rdx, rax
	add rsi, r9
	add rsi, 4
		; si se considera la siguiente matriz:
		;		| pixel3 | pixel2 | pixel1 |
		;		| pixel7 | pixel6 | pixel5 |
		;		| pixel11 | pixel10 | pixel9 |
		;
	ciclo_columnas:		;proceso de a 9 pixeles para obtener 1 en la imagen destino
		; xmm0, xmm1 y xmm2 van a guardar las tres filas de la matriz que contienen los pixeles
		movdqu xmm1, [rdi]		;xmm1 = | ---- | pixel3 | pixel2 | pixel1 |
		movdqu xmm2, [rdi+r8]	;xmm2 = | ---- | pixel6 | pixel5 | pixel4 |
		movdqu xmm3, [rdi+r8*2]	;xmm3 = | ---- | pixel9 | pixel8 | pixel7 |
					
		movdqu xmm4, xmm1		;xmm4 = | --- | a3,r3,g3,b3 | a2,r2,g2,b2 | a1,r1,g1,b1 | 
		punpcklbw xmm4, xmm7	;xmm4 = |Pixel2(a,r,g,b) | Pixel1(a,r,g,b)|
		pslldq xmm1, 4			;	
		psrldq xmm1, 12			;xmm1 = | *** | *** | *** | Pixel3(a,r,g,b) |
		punpcklbw xmm1, xmm7	;xmm1 = | *** |	Pixel3(a,r,g,b) |
		movdqu xmm5, xmm4
		pcmpgtw xmm5, xmm1		;xmm5 = el resultado de la comparacion (máscara de la comparacion)
		pand xmm4, xmm5
		pxor xmm5, xmm8			;invierto los bits del resultado
		pand xmm1, xmm5			;el resultado de ls componentes mayores entre pixeles 1,2 y 3
		por	xmm1, xmm4			; xmm1 = | Pixel2(a,r,g,b) | max_pixel_1_3(a,r,g,b) |
		
		movdqu xmm6, xmm2		;guardo la segunda fila (el pixel en xmm6)
		
		movdqu xmm4, xmm2		;xmm4 = | --- | Pixel6(a,r,g,b) | Pixel5(a,r,g,b) | Pixel4(a,r,g,b) | 
		punpcklbw xmm4, xmm7	;xmm4 = | Pixel5(a,r,g,b) | Pixel4(a,r,g,b) | 
		pslldq xmm2, 4			;	
		psrldq xmm2, 12			;xmm2 = | *** | *** | *** | Pixel6(a,r,g,b) |
		punpcklbw xmm2, xmm7	;xmm2 = | *** | Pixel6(a,r,g,b) |
		movdqu xmm5, xmm4
		pcmpgtw xmm5, xmm2		; xmm5 = el resultado de la comparacion xmm4, xmm2
		pand xmm4, xmm5
		pxor xmm5, xmm8			;invierto los bits del resultado
		pand xmm2, xmm5			;el resultado de los componentes mayores entre pixeles 4,5 y 6
		por	xmm2, xmm4			;xmm2 = | Pixel5(a,r,g,b) | max_pixel_4_6(a,r,g,b) |
		
		movdqu xmm5, xmm1
		pcmpgtw xmm5, xmm2		; xmm5 = el resultado de la comparacion
		pand xmm1, xmm5
		pxor xmm5, xmm8			;invierto los bits del resultado
		pand xmm2, xmm5			;el resultado de los componentes mayores entre pixeles 1,2,3,4,5 y 6
		por xmm1, xmm2			; xmm1 = | max_pixel_5_2(a,r,g,b) | max_pixel_1_3_4_6(a,r,g,b) |
								
		movdqu xmm4, xmm3		;xmm4 = | --- | Pixel9(a,r,g,b) | Pixel8(a,r,g,b) | Pixel7(a,r,g,b) | 
		punpcklbw xmm4, xmm7	;xmm4 = | Pixel8(a,r,g,b) | Pixel7(a,r,g,b) |
		pslldq xmm3, 4			;	
		psrldq xmm3, 12			;xmm3 = 
		punpcklbw xmm3, xmm7	;xmm3 = | *** | Pixel9(a,r,g,b) |
		movdqu xmm5, xmm4
		pcmpgtw xmm5, xmm3		; xmm5 = el resultado de la comparacion
		pand xmm4, xmm5
		pxor xmm5, xmm8			;invierto los bits del resultado
		pand xmm3, xmm5			;el resultado de los componentes mayores entre pixeles 7,8 y 9
		por xmm3, xmm4			;xmm3 = | Pixel8(a,r,g,b) | max_pixel_7_9(a,r,g,b) |
		
		movdqu xmm5, xmm1
		pcmpgtw xmm5, xmm3		; xmm5 = el resultado de la comparacion
		pand xmm1, xmm5
		pxor xmm5, xmm8			;invierto los bits del resultado
		pand xmm3, xmm5			;el resultado de los componentes mayores entre pixeles 1,2,3,4,5,6,7,8 y 9
		por xmm1, xmm3			; xmm1 = | max_pixel_2_5_8(a,r,g,b) | max_pixel_1_3_4_6_7_9(a,r,g,b) |
		
		movdqu xmm2, xmm1		;
		punpcklwd xmm1, xmm7	;xmm1 = | max_pixel_1_3_4_6_7_9(a,r,g,b) |
		
		punpckhwd xmm2, xmm7	;xmm2 = | max_pixel_2_5_8(a,r,g,b) |
		movdqu xmm5, xmm1
		pcmpgtw xmm5, xmm2		; xmm5 = el resultado de la comparacion
		pand xmm1, xmm5
		pxor xmm5, xmm8			;invierto los bits del resultado
		pand xmm2, xmm5			;el resultado de los componentes mayores entre pixeles 1,2,3,4,5,6,7,8 y 9 esta en xmm1
		por xmm1, xmm2			; xmm1 = |max_a|max_r|max_g|max_b|						
		
		movdqu xmm2, xmm1		;
		movdqu xmm3, xmm1
		pand xmm1, xmm9			;xmm1 = |000|000|000|max_b|
		psrldq xmm2, 4		
		pand xmm2, xmm9			;xmm2 = |0000|0000|0000|maxg|
		psrldq xmm3, 8
		pand xmm3, xmm9			;xmm3 = |0000|0000|0000|maxr|
		; aplico las funciones fi con cada componente
		movq r12, xmm1		;r12 = el maximo b
		movq r13, xmm2		;r13 = el maximo g
		movq r14, xmm3		;r14 = el maximo r
		pxor xmm1, xmm1
		call fi_b
		pxor xmm2, xmm2 
		call fi_g
		pxor xmm3, xmm3
		call fi_r
		
		; xmm1 = |0000|0000|0000|fi_b|
		; xmm2 = |0000|0000|0000|fi_g|
		; xmm3 = |0000|0000|0000|fi_r|
		;obtengo el pixel_5 
		
		pshufd xmm3, xmm3, 0xC6  ; xmm3 = |0000|fi_r|0000|0000|
		pshufd xmm2, xmm2, 0xE1  ; xmm2 = |0000|0000|fi_g|0000|
		
		addps xmm1, xmm2
		addps xmm1, xmm3		; xmm2 = |0000|fi_r|fi_g|fi_b|
		
		pslldq xmm6, 8
		psrldq xmm6, 12			;xmm6 = |0000|0000|0000|pixel_5| 
		punpcklbw xmm6, xmm7 	;xmm6 = |0000|0000|0a0r|0g0b|
		punpcklwd xmm6, xmm7 	;xmm6 = |000a|000r|000g|000b|
		
		cvtdq2ps xmm6, xmm6 	; xmm6 = | float(pixel_5_r) | float(pixel_5_g) | float(pixel_5_b) |
		
		mulps xmm1, xmm6		;xmm3 = fi_r* pixel_5_r | fi_g* pixel_5_g | fi_b* pixel_5_b
		cvtps2dq xmm1, xmm1 	; xmm1 = | r | g | b |
				
		packusdw xmm1, xmm7 	; xmm1 = |0000| 0000| 000r| 0g0b |
		packuswb xmm1, xmm7		; xmm1 = |0000|0000|0000|0rgb|
		movdqu xmm6, [filtro_A]
		paddb  xmm1, xmm6
		;movq rbx, xmm1
		movd [rsi], xmm1
		
		add rdi, 4
		add rsi, 4
		dec rdx
		cmp rdx, 0
		jne ciclo_columnas
		
		
	
	.seguir:
	dec rcx
	lea r10, [r10+r8]
	lea r11, [r11+r9]
	jmp ciclo_filas
	
	fin:
	pop rbx
	pop r14
	pop r13
	pop r12
	pop rbp
	ret


fi_b:
	cmp r14, r12
	jge .no_3
	cmp r13, r12
	jge .no_3
	movdqu xmm1, xmm11
	jmp .fin_b
	.no_3:
	movdqu xmm1, xmm12  
	.fin_b:
	ret
	
fi_g:
	cmp r14, r13
	jge .no_2
	cmp r13, r12
	jl .no_2
	movdqu xmm2, xmm11
	jmp .fin_g
	.no_2:
	movdqu xmm2, xmm12
	.fin_g:
	ret

fi_r:
	cmp r14, r13
	jl .no
	cmp r14, r12
	jl .no
	movdqu xmm3, xmm11
	jmp .fin_r
	.no:
	movdqu xmm3, xmm12
	.fin_r:
	ret
	
