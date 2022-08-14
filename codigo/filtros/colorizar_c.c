
#include "../tp2.h"

unsigned char maximo(unsigned char m1, unsigned char m2, unsigned char m3,
					unsigned char m4, unsigned char m5, unsigned char m6,
					unsigned char m7, unsigned char m8, unsigned char m9);
unsigned char max ( unsigned char a, unsigned char b );
float minimo(float a, float b);
float fi_r(float alpha, unsigned char max_r, unsigned char max_g, unsigned char max_b);
float fi_g(float alpha, unsigned char max_r, unsigned char max_g, unsigned char max_b);
float fi_b(float alpha, unsigned char max_r, unsigned char max_g, unsigned char max_b);

void colorizar_c (
	unsigned char *src,
	unsigned char *dst,
	int cols,
	int filas,
	int src_row_size,
	int dst_row_size,
	float alpha
) {
	unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
	unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;
	
	unsigned int f;
	unsigned int c;
	unsigned char max_r, max_g, max_b;
	float f_r, f_g, f_b, f_aux;
	bgra_t *p_s_1, *p_s_2, *p_s_3, *p_s_4, *p_s_5, *p_s_6, *p_s_7, *p_s_8, *p_s_9, *p_d;
	
	for (f=0; f<(filas-2); ++f){
		for (c=0; c<(cols-2); ++c){
			p_s_1 = (bgra_t*) &src_matrix[f][c * 4];
			p_s_2 = (bgra_t*) &src_matrix[f][(c+1) * 4];
			p_s_3 = (bgra_t*) &src_matrix[f][(c+2) * 4];
			p_s_4 = (bgra_t*) &src_matrix[f+1][c * 4];
			p_s_5 = (bgra_t*) &src_matrix[f+1][(c+1) * 4];
			p_s_6 = (bgra_t*) &src_matrix[f+1][(c+2) * 4];
			p_s_7 = (bgra_t*) &src_matrix[f+2][c * 4];
			p_s_8 = (bgra_t*) &src_matrix[f+2][(c+1) * 4];
			p_s_9 = (bgra_t*) &src_matrix[f+2][(c+2) * 4];
			p_d = (bgra_t*) &dst_matrix[f+1][(c+1) * 4];
			
			max_r = maximo(p_s_1->r, p_s_2->r, p_s_3->r, 
							p_s_4->r, p_s_5->r, p_s_6->r,
							p_s_7->r, p_s_8->r, p_s_9->r);
						
			max_g = maximo(p_s_1->g, p_s_2->g, p_s_3->g, 
							p_s_4->g, p_s_5->g, p_s_6->g,
							p_s_7->g, p_s_8->g, p_s_9->g);
							
			max_b = maximo(p_s_1->b, p_s_2->b, p_s_3->b, 
							p_s_4->b, p_s_5->b, p_s_6->b,
							p_s_7->b, p_s_8->b, p_s_9->b);
			
			f_r = fi_r(alpha, max_r, max_g, max_b);
			f_aux = (float) (p_s_5->r);
			p_d->r = (unsigned char) minimo(255.0,(f_r * f_aux));
						
			f_g = fi_g(alpha, max_r, max_g, max_b);
			f_aux = (float) (p_s_5->g);
			p_d->g =(unsigned char) minimo(255.0,(f_g*f_aux));
			
			f_b = fi_b(alpha, max_r, max_g, max_b);
			f_aux = (float) (p_s_5->b);
			p_d->b =(unsigned char) minimo(255.0,(f_b*f_aux));
			
			//p_s->a = p_d_5->a;
						
		}
	}
	
}


unsigned char maximo(unsigned char m1, unsigned char m2, unsigned char m3,
					unsigned char m4, unsigned char m5, unsigned char m6,
					unsigned char m7, unsigned char m8, unsigned char m9){
	unsigned char _max = 0;
	_max = max(m1, m2);
	_max = max(_max, m3);
	_max = max(_max, m4);
	_max = max(_max, m5);
	_max = max(_max, m6);
	_max = max(_max, m7);
	_max = max(_max, m8); 
	_max = max(_max, m9);
	return _max;
}

unsigned char max( unsigned char a, unsigned char b ) {
	 if (a > b) {
		 return a;
	}else{
		return b;
	}
}

float minimo(float a, float b) {
	if (a < b) {
		return a;
	}else{
		return b;
	}
}

float fi_r(float alpha, unsigned char max_r, unsigned char max_g, unsigned char max_b){
	if ((max_r >= max_g) && (max_r >= max_b)) {
		return (1.0 + alpha);
	}else{
		return (1.0 - alpha);
	}
}

float fi_g(float alpha, unsigned char max_r, unsigned char max_g, unsigned char max_b){
	if ((max_r < max_g) && (max_g >= max_b)) {
		return (1.0 + alpha);
	}else{
		return (1.0 - alpha);
	}
}

float fi_b(float alpha, unsigned char max_r, unsigned char max_g, unsigned char max_b){
	if ((max_r < max_b) && (max_g < max_b)) {
		return (1.0 + alpha);
	}else{
		return (1.0 - alpha);
	}
}
