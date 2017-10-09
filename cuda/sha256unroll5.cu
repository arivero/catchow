#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include "sha256.h"

#define dec(a) ((a)+48)
//If a<10 add '0' (48) else add 87 ('a'-10)
#define hex(a) ((a)+((a)<10?48:87))

__constant__  char dni[]="TRWAGMYFPDXBNJZSQVHLCKE";
__constant__  unsigned int C[64] = { 0x428a2f98, 0x71374491, 0xb5c0fbcf,
		0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, 0xd807aa98,
		0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7,
		0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f,
		0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8,
		0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85,
		0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e,
		0x92722c85, 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819,
		0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116, 0x1e376c08, 0x2748774c,
		0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3, 0x748f82ee,
		0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7,
		0xc67178f2 };


__global__ void sha256cat(unsigned char* datain, unsigned char* strdataout) {
        register unsigned int context_state[8];
	register unsigned int shadowRegister[8];
	register unsigned int messageSchedule[16]; 
        for (long int letra=0; letra <23; letra++){
        long int hilo=(blockDim.y*blockIdx.y+threadIdx.y)*blockDim.x*gridDim.x +(blockDim.x*blockIdx.x+threadIdx.x);
        hilo=hilo;
        //long int hilo= ( blockIdx.x*blockDim.x + threadIdx.x);
        //int letra = hilo/(100*31*12);
        int fecha= hilo;//- letra*31*12*100;
        hilo+= (31*12*90)*letra;
        int year= fecha / (31*12);
        int resto=fecha - year*31*12;
        int mes = resto /31;
        int dia = resto -( mes * 31);
        mes++;
        dia++;
        year+=10;
        for (int j=0; j < 16; j++) { messageSchedule[j]=0x00000000;}
        messageSchedule[0] = (datain[0] << 24)|(datain[1] << 16)|(datain[2] << 8)|(datain[3]);
        messageSchedule[1] = (datain[4] << 24)|(dni[letra] << 16)|(datain[6] << 8)|(datain[7]);
        messageSchedule[2] = (dec(year/10) << 24)|(dec(year%10) << 16)|(dec(mes/10) << 8)|(dec(mes%10));
        messageSchedule[3] = (dec(dia/10) << 24)|(dec(dia%10) << 16)|(datain[14] << 8)|(datain[15]);
        messageSchedule[4] = (datain[16] << 24)|(datain[17] << 16)|(datain[18] << 8)|(0x00000080);

        messageSchedule[15]|= 0x00000000 | (19*8);
 
        context_state[0] = 0x6a09e667;
        context_state[1] = 0xbb67ae85;
        context_state[2] = 0x3c6ef372;
        context_state[3] = 0xa54ff53a;
        context_state[4] = 0x510e527f;
        context_state[5] = 0x9b05688c;
        context_state[6] = 0x1f83d9ab;
        context_state[7] = 0x5be0cd19;

                shadowRegister[0] = 0x6a09e667;
                shadowRegister[1] = 0xbb67ae85;
                shadowRegister[2] = 0x3c6ef372;
                shadowRegister[3] = 0xa54ff53a;
                shadowRegister[4] = 0x510e527f;
                shadowRegister[5] = 0x9b05688c;
                shadowRegister[6] = 0x1f83d9ab;
                shadowRegister[7] = 0x5be0cd19;

#pragma unroll 64
 for (int i = 0; i < 64; i++) {
        if (i>=16){     messageSchedule[i % 16] = sigma1(messageSchedule[(i - 2)%16])
                                + messageSchedule[(i - 7)%16] + sigma0(messageSchedule[(i - 15)%16])
                                + messageSchedule[(i - 16)%16];
         }
                unsigned int textRegister1 = shadowRegister[7]
                                + epsilon1(shadowRegister[4])
                                + choice(shadowRegister[4], shadowRegister[5],
                                                shadowRegister[6]) + C[i] + messageSchedule[i%16];
                unsigned int textRegister2 = epsilon0(shadowRegister[0])
                                + majority(shadowRegister[0], shadowRegister[1],
                                                shadowRegister[2]);
#pragma unroll 7
                for (int j = 7; j > 0; j--) {
                        shadowRegister[j] = shadowRegister[j - 1];
                }
                shadowRegister[0] = textRegister1 + textRegister2;
                shadowRegister[4] += textRegister1;
        }

#pragma unroll 1715
        for (int j = 0; j < 1715; j++) {   // here is the main loop

#pragma unroll 16
        for (int i = 0, j = 0; i < 16; i++, j += 4) {
                unsigned char jm = j >> 3;
                unsigned int acc =  context_state[jm] + shadowRegister[jm];
                unsigned char im = (j >> 1) & 0x0000003;
                unsigned char hm = (acc >> (24- im*8)) & 0x000000ff;
                messageSchedule[i] = (hex(hm >> 4) << 24) | (hex(hm %16) << 16);
                im= ((j+2) >> 1) & 0x0000003; 
                hm = (acc >> (24- im*8)) & 0x000000ff;
                messageSchedule[i]|= (hex(hm >> 4) << 8) | (hex(hm %16) );
        }

                context_state[0] = 0x6a09e667;
                context_state[1] = 0xbb67ae85;
                context_state[2] = 0x3c6ef372;
                context_state[3] = 0xa54ff53a;
                context_state[4] = 0x510e527f;
                context_state[5] = 0x9b05688c;
                context_state[6] = 0x1f83d9ab;
                context_state[7] = 0x5be0cd19;

                shadowRegister[0] = 0x6a09e667;
                shadowRegister[1] = 0xbb67ae85;
                shadowRegister[2] = 0x3c6ef372;
                shadowRegister[3] = 0xa54ff53a;
                shadowRegister[4] = 0x510e527f;
                shadowRegister[5] = 0x9b05688c;
                shadowRegister[6] = 0x1f83d9ab;
                shadowRegister[7] = 0x5be0cd19;


#pragma unroll 64
        for (int i = 0; i < 64; i++) {
                if (i >=16) {
                           messageSchedule[i % 16] = sigma1(messageSchedule[(i - 2)%16])
                                + messageSchedule[(i - 7)%16] + sigma0(messageSchedule[(i - 15)%16])
                                + messageSchedule[(i - 16)%16];
                }
                unsigned int textRegister1 = shadowRegister[7]
                                + epsilon1(shadowRegister[4])
                                + choice(shadowRegister[4], shadowRegister[5],
                                                shadowRegister[6]) + C[i] + messageSchedule[i%16];
                unsigned int textRegister2 = epsilon0(shadowRegister[0])
                                + majority(shadowRegister[0], shadowRegister[1],
                                                shadowRegister[2]);
#pragma unroll 7
                for (int j = 7; j > 0; j--) {
                        shadowRegister[j] = shadowRegister[j - 1];
                }
                shadowRegister[0] = textRegister1 + textRegister2;
                shadowRegister[4] += textRegister1;
        }

#pragma unroll  8
        for (int i = 0; i < 8; i++) {
                shadowRegister[i]+= context_state[i] ; //cd is the init constant here
                context_state[i]=shadowRegister[i];
        }

#pragma unroll 16
        for (int i=0; i < 16; i++) {
        //for (int i = 0, j = 0; i < 16; i++, j += 4) {
         //solo 62= 512>>8 y 0 = 0x80 son relevantes. Los demas 0
        messageSchedule[i]=0;
        }
        messageSchedule[0]= 0x80 << 24;
        messageSchedule[15]= (512 >> 8) <<8;
                
#pragma unroll 64
        for (int i = 0; i < 64; i++) {
             if (i>=16) {
                           messageSchedule[i % 16] = sigma1(messageSchedule[(i - 2)%16])
                                + messageSchedule[(i - 7)%16] + sigma0(messageSchedule[(i - 15)%16])
                                + messageSchedule[(i - 16)%16];
             }
                unsigned int textRegister1 = shadowRegister[7]
                                + epsilon1(shadowRegister[4])
                                + choice(shadowRegister[4], shadowRegister[5],
                                                shadowRegister[6]) + C[i] + messageSchedule[i%16];
                unsigned int textRegister2 = epsilon0(shadowRegister[0])
                                + majority(shadowRegister[0], shadowRegister[1],
                                                shadowRegister[2]);
#pragma unroll 7
                for (int j = 7; j > 0; j--) {
                        shadowRegister[j] = shadowRegister[j - 1];
                }
                shadowRegister[0] = textRegister1 + textRegister2;
                shadowRegister[4] += textRegister1;
        }

      } // EXIT MAIN LOOP


#pragma unroll 8
                for (int j = 0; j < 8; j++) {
                        unsigned int  acc = context_state[j] + shadowRegister[j];
#pragma unroll 4
                 for (int i = 0; i < 4; i++) {
                        unsigned char h= (acc >> (24 - i * 8)) & 0x000000ff;
                        strdataout[64*hilo+2*(i + 4 * j)]= hex(h >> 4 );
                        strdataout[64*hilo+2*(i + 4 * j)+1]= hex(h%16);                      
                }
                }

}
}

__device__ void sha256Transform(unsigned int * context_state, unsigned char * data) {
}


