// C standard header files
#include <stdio.h>
#include <omp.h>
// CUDA header files
#include <cuda_runtime.h>

#define cudaCheck(call) __cudaCheck(call, __FILE__, __LINE__)
inline void __cudaCheck(cudaError err, const char* file, int line) {
#ifndef NDEBUG
	if (err != cudaSuccess) {
		fprintf(stderr, "%s(%d): CUDA error: %s\n", __FILE__, __LINE__,
				cudaGetErrorString(err));
		exit (EXIT_FAILURE);
	}
#endif
}

#include "sha256.h"


//G969 has 2GPCs, 2*512 = 1024 cores
//1 GPC GPU Cluster has 4 SMM
//1 SMM has 4 little regions
//1 region has 4*8=32 cores
__global__ void hashtestGPU();

int myStrCmp(const void *s1, const void *s2) {
  const char *key = (char *)s1;
  //const char * const *arg = (char **) s2;
  const char *arg= (char *)s2;
   //printf("myStrCmp: s1(%p): %s, s2(%p): %.75s\n", s1, key, s2, arg);
  return strncmp(key, arg,64);
}

int main(int argc, char* argv[]) {
        //cudaSetDevice(0);
	//hashtestGPU<<<1, 1>>>();
	//cudaCheck(cudaDeviceReset());
        FILE *f = fopen("./somehashes.txt", "r");
        typedef char fixed_string[65];
        fixed_string *hashes;
        //char (* hashes)[65];
        hashes = (fixed_string *) malloc(5338814*65+1);
        fread(hashes,5338814*65,1,f);
        fclose(f);
        //printf("fichero leido\n");
        //printf("%.98s\n",hashes[5120929]);
        //qsort(hashes,5338814,65,(int(*)(const void *,const void*)) strcmp);
        //printf("%.98s\n",hashes[65*5120929]); 
        //unsigned char other[]="00014Z1965061308034";
    
        unsigned char *o,*h;
        unsigned char * hash;
        hash=(unsigned char *) malloc(64*31*12*100*2*23+1);
        printf("lets allocate\n");
        cudaDeviceSynchronize();
        cudaDeviceSetCacheConfig(cudaFuncCachePreferL1);
        printf("Cuda status: %s\n", cudaGetErrorString( cudaGetLastError() ) ); 
        cudaMalloc(&o,20);
        printf("Cuda status: %s\n", cudaGetErrorString( cudaGetLastError() ) );
        printf("%d \n",cudaMalloc(&h,64*31*12*90*23));
    char * prov[]={"08","25", "43", "17"};
    for (int trito=757;trito<758;trito++){
        int dni=0;
      //for (int dni=50000; dni <50001 ;dni++) {
        for (int pr=0; pr <4; pr++){
        char distrito[6];
        sprintf(distrito, "%.2s%03d",prov[pr],trito);
        char base[20];
        sprintf(base,"%05dP19650613%.5s",dni,distrito);
        base[19]='\0';
        // for (int l=0; l <23/23; l++) {
        char letrasDNI[] ="TRWAGMYFPDXBNJZSQVHLCKE";
        //base[5]=letrasDNI[l];
        printf("base %s\n",base);
        //unsigned char hash0[]="4efd89e2f3bb5f32e35d9249b1d90693a5a4eea69cba351e8540a1799d2d0e3b";
        cudaCheck(cudaMemcpy(o, base, 20, cudaMemcpyHostToDevice));
        //sha256cat<<<80*23,31*15>>>(o,h);
          dim3 threadsPerBlock(30,31);
          sha256cat<<<15*3,threadsPerBlock>>>(o,h); //23 ahora detro del 
        //cudaMemcpy(hash,h,64*31*12*100,cudaMemcpyDeviceToHost);
        //printf("output %.64s\n",&hash[64*(12+31*5+31*12*65)]);
        //printf("output %.64s\n",hash);
        //printf("compare%s\n",hash0);
        cudaCheck(cudaMemcpy(hash,h,64*31*12*90*23,cudaMemcpyDeviceToHost));
        #pragma omp parallel num_threads(6)
        #pragma omp for
          for (int x=0; x<31*12*90*23; x++ ) {
            //if (l==8 && x==35743) {
            char * pItem;
            pItem = (char *) bsearch(&hash[64*x],hashes,5338814,65, myStrCmp);
            if (pItem!=NULL) {
               int letra = x/(90*31*12);
               int fecha= x- letra*31*12*90;
               int year= fecha / (31*12);
               int resto=fecha - year*31*12;
               int mes = resto /31;
               int dia = resto -( mes * 31);
               mes++;
               dia++;
               year+=10;
            // if (dia==1 && mes==2 && year==96) {
               printf("%05d%c 19%02d%02d%02d %.5s encontrado %.64s %d \n", dni,letrasDNI[letra],
                       year, mes, dia, distrito, &hash[64*x],x);
             } //if
          }
        //}
      }
      }
        cudaFree(o);
        cudaFree(h);
        free(hashes);
	cudaCheck(cudaDeviceReset());
}

