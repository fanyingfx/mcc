int main(void){
    int sum = 0;
    for(int i=1; i <= 0;i= i+1){
        sum=sum +i;
    }
    return sum;
}


/*
<init>
.start:
    <cond_jmp_end>
    <body>
.cont:
    <post>
    <jmp_start>
.end:
*/