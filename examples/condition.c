int main(void){
    int a=2;
    int b=3;
    when {
        a > 2 -> return a;
        b >= 3 -> return b;
        else -> return a+b;
    }
}