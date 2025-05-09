int main(void){
    int a = 1;
    int sum = 0;
    while (a <= 100){
        sum = sum + a;
        a  = a+ 1;
        if (a > 11){
            break;
        }
        continue;
    }

    return sum;
}