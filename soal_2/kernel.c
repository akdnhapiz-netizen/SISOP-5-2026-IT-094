int cursor = 0;
char color = 0x07;

void putInMemory(int segment, int address, char character);
int getChar();

void printChar(char c) {
    if (c == '\n' || c == '\r') {
        /* Menggunakan simulasi pembagian/modulus untuk enter tanpa '/' */
        int temp = cursor;
        while (temp >= 160) temp -= 160;
        cursor = cursor + (160 - temp);
    } else if (c == '\b') {
        if (cursor > 0) {
            cursor -= 2;
            putInMemory(0xB800, cursor, ' ');
            putInMemory(0xB800, cursor + 1, color);
        }
    } else {
        putInMemory(0xB800, cursor, c);
        putInMemory(0xB800, cursor + 1, color);
        cursor += 2;
    }
    if (cursor >= 4000) cursor = 0;
}

void printString(char* str) {
    int i = 0;
    while (str[i] != '\0') {
        printChar(str[i]);
        i++;
    }
}

void newline() {
    printChar('\n');
}

void clearScreen() {
    int i;
    for (i = 0; i < 4000; i += 2) {
        putInMemory(0xB800, i, ' ');
        putInMemory(0xB800, i + 1, color);
    }
    cursor = 0;
}

void readString(char* buffer) {
    int i = 0;
    char c;
    while (1) {
        c = getChar();
        if (c == '\r' || c == '\n') {
            buffer[i] = '\0';
            newline();
            break;
        } else if (c == '\b') {
            if (i > 0) {
                i--;
                printChar('\b');
            }
        } else {
            buffer[i++] = c;
            printChar(c);
        }
    }
}

int strcmp(char* s1, char* s2) {
    int i = 0;
    while (s1[i] == s2[i]) {
        if (s1[i] == '\0') return 1;
        i++;
    }
    return 0;
}

int startsWith(char* str, char* prefix) {
    int i = 0;
    while (prefix[i] != '\0') {
        if (str[i] != prefix[i]) return 0;
        i++;
    }
    return 1;
}

int atoi(char* str) {
    int res = 0;
    int i = 0;
    while (str[i] == ' ') i++; 
    while (str[i] != '\0' && str[i] >= '0' && str[i] <= '9') {
        res = res * 10 + (str[i] - '0');
        i++;
    }
    return res;
}

char* intToString(int n) {
    static char buf[16];
    int i = 0, j = 0;
    char temp[16];

    if (n == 0) {
        buf[0] = '0';
        buf[1] = '\0';
        return buf;
    }
    if (n < 0) {
        buf[i++] = '-';
        n = -n;
    }
    /* Simulasi modulo dan pembagian tanpa operator % dan / */
    while (n > 0) {
        int q = 0, rem = n;
        while (rem >= 10) {
            rem -= 10;
            q++;
        }
        temp[j++] = rem + '0';
        n = q; 
    }
    while (j > 0) {
        buf[i++] = temp[--j];
    }
    buf[i] = '\0';
    return buf;
}

int factorial(int n) {
    int i, res = 1;
    for (i = 1; i <= n; i++) res *= i;
    return res;
}

void main() {
    char cmd[64];
    clearScreen();
    printString("Welcome to Assistant's Last Gift");
    newline();
    printString("type 'help'");
    newline();
    newline();

    while (1) {
        printString("> ");
        readString(cmd);

        if (strcmp(cmd, "help")) {
            printString("Commands: check, add, sub, fac, season, triangle, clear");
        } 
        else if (strcmp(cmd, "check")) {
            printString("ok");
        } 
        else if (startsWith(cmd, "add ")) {
            int i = 4, a = 0, b = 0;
            a = atoi(cmd + i);
            while(cmd[i] != ' ' && cmd[i] != '\0') i++;
            while(cmd[i] == ' ') i++;
            b = atoi(cmd + i);
            printString(intToString(a + b));
        } 
        else if (startsWith(cmd, "sub ")) {
            int i = 4, a = 0, b = 0;
            a = atoi(cmd + i);
            while(cmd[i] != ' ' && cmd[i] != '\0') i++;
            while(cmd[i] == ' ') i++;
            b = atoi(cmd + i);
            printString(intToString(a - b));
        } 
        else if (startsWith(cmd, "fac ")) {
            int n = atoi(cmd + 4);
            /* Limit 16-bit signed integer di Bochs OS adalah 32767. 
               Faktorial maksimal yang aman adalah 7! (5040). 8! adalah 40320 (melebihi limit signed). */
            if (n > 7) {
                printString("Know your limit little bro.");
            } else {
                printString(intToString(factorial(n)));
            }
        } 
        else if (startsWith(cmd, "season ")) {
            char* s = cmd + 7;
            if (strcmp(s, "winter")) color = 0x09;
            else if (strcmp(s, "spring")) color = 0x0A;
            else if (strcmp(s, "summer")) color = 0x0E;
            else if (strcmp(s, "fall")) color = 0x06;
            else if (strcmp(s, "radiant")) color = 0x0D;
            
            printString(s);
            printString(" mode");
        } 
        else if (startsWith(cmd, "triangle ")) {
            int n = atoi(cmd + 9);
            int r, c;
            for (r = 1; r <= n; r++) {
                for (c = 1; c <= r; c++) {
                    printChar('x');
                }
                if (r < n) newline();
            }
        } 
        else if (strcmp(cmd, "clear")) {
            clearScreen();
            /* Prevent extra newline print out on clear */
            continue; 
        } 
        else if (cmd[0] != '\0') {
            printString("Command not found");
        }
        
        newline();
    }
}
