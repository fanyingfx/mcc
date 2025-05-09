int main(void){
    int a = 1;
    int sum = 0;

    do{

        sum = sum + a;
        a  = a+ 1;

        continue;

        if (a > 11){
            break;
        }
    } while (a <= 100);
    return sum;
}
/*
.start:
    <body>
.cont:
    <cond_jmp_end>
    <jmp_start>
.end:

*/