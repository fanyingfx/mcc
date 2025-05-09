int main(void){
    int a = 1;
    int sum = 0;

    while (a <= 100){
        sum = sum + a;
        a  = a + 1;
        // if (a > 11){
        //     break;
        // }
        // continue;
    }

    return sum;
}
/*
.start:
    <cond_jmp_end>
    <body>
    <jmp_start>
.end:
*/