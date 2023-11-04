.data
	#Todos os arquivos necessários devem estar na mesma pasta que o arquivo .asm"
    xTrain:         .asciiz  "C:/Users/Joel/Documents/USP/OAC 2/EP1/xtrain.txt"
    xTrainBuffer:   .space 20480
    xTest:          .asciiz   "C:/Users/Joel/Documents/USP/OAC 2/EP1/xtest.txt"
    xTestBuffer:    .space  10240
    yTrain:         .asciiz  "C:/Users/Joel/Documents/USP/OAC 2/EP1/ytrain.txt"
    yTrainBuffer:   .space 10240
    yTest:          .asciiz   "C:/Users/Joel/Documents/USP/OAC 2/EP1/ytest.txt"      
    yTestBuffer:    .space 10240
    zero:           .float 0.0	              #os co registradores não possuem um $zero, então reservo aqui
    dez:            .float 10.0	              #para os cálculos de multiplicação e divisão por 10
    byteBuffer:     .space 1                  #buffer para fazer a leitura byte a byte
    maxFloat:       .float 3.40e+38f          #valor máximo para um float, que será usado inicialmente no registrador que vai salvar a menor distância, garantindo que a primeira comparação sempre seja verdadeira.
.text

main:

    # Inicialização
    li $t0, 0           # $t0 é usado para manter o índice na sequência de caracteres
    li $t3, 0           # $t3 é usado para manter a posição do dígito decimal
    li $t7, 0           # $t7 será usado para registrar a quantidade de números que estão sendo lidos
    lwc1 $f4, dez       # $f4 será usado para multiplicar e dividir os valores por 10
    lwc1 $f31, zero     # os corregistradores 1 não possuem um registrador reservado para atuar como zero, então estou definindo aqui
    lwc1 $f30, maxFloat #valor máximo que pode haver em um float, para garantir a primeira comparação sendo True 
    la $s1, byteBuffer
    li $s3, 0           #o registrador $s6 vai salvar o valor da linha com a menor distância para que possa atualizar no final.
    li $s4, 0           #o registrador $s4 vai registrar o valor da linha atual de xTrain, para saber qual linha salvar em $s6
    li $s2, 0           #o registrador $s2 será usado para guardar o tamanho do arquivo de saída ytrain
    la $s7, yTrainBuffer
      
    jal abrirArquivos
    jal loopInteiro




abrirArquivos:
    
    li $v0, 13                  # syscall de abertura de arquivo
    la $a0, xTest               # carrega endereço com nome do arquivo para abertura
    li $a1, 0                   # indicador de abertura em modo leitura
    li $a2, 0     		# ignorar permissões
    syscall       		# chamada de sistema que realiza a abertura
    move $s0, $v0   		# Salvando o descritor de abertura do arquivo em um registrador para uso ao longo do programa.
    
    
    li $v0, 13                  # syscall de abertura de arquivo
    la $a0, xTrain              # carrega endereço com nome do arquivo para abertura
    li $a1, 0                   # indicador de abertura em modo leitura
    li $a2, 0     		# ignorar permissões
    syscall       		# chamada de sistema que realiza a abertura
    move $s5, $v0               # o descritor do arquivo Xtrain ficará em s5
    
    
    li $v0, 13                  # syscall de abertura de arquivo
    la $a0, yTest               # carrega endereço com nome do arquivo para abertura
    li $a1, 0                   # indicador de abertura em modo leitura
    li $a2, 0     		# ignorar permissões
    syscall       		# chamada de sistema que realiza a abertura
    move $s6, $v0               # o descritor do arquivo yTeste ficará em s6
    
    jr $ra                      #volta para o main e continua o programa

loopInteiro:
    # ler um byte
    li $v0, 14     # syscall para ler do arquivo
    move $a0, $s0  # descritor do arquivo está em $s0
    move $a1, $s1  # endereço do buffer de destino
    li $a2, 1      # tamanho do buffer (1 pois estamos fazendo leitura byte a byte)
    syscall       # lê o próximo byte do arquivo
    
    lb $t1, 0($a1)
    # Verificar se chegou ao final da sequência
    li $t2, 13              #ascii char (ch)
    beq $t1, $t2, oitavoNumero
    beqz $v0, encerrarPrograma
    
    # Verificar se o caractere é um ponto decimal
    li $t2, 46          # ASCII '.'
    beq $t1, $t2, continueDecimal # Se for um ponto decimal, vá para pular ponto e começa a leitura da parte decimal a partir do próximo byte
    
    #verificar se é virgula 
    li $t2, 44
    beq $t1, $t2, proximoNumero
    
    #atualiza a parte inteira
    li $t2, 48          # ASCII '0'
    sub $t1, $t1, $t2   # Subtrai '0' do caractere para obter o valor inteiro
    mul.s $f12, $f12, $f4 # Multiplica o valor atual por 10
    mtc1 $t1, $f0       # Carrega o valor inteiro na parte inteira de $f0
    cvt.s.w $f0, $f0  #remove o resto que surge por causa da transformação
    add.s $f12, $f12, $f0 # Adiciona o dígito ao valor
    j continue
    
 loopDecimal:
 
     # ler um byte
    li $v0, 14     # syscall para ler do arquivo
    move $a0, $s0  # descritor do arquivo está em $s0
    move $a1, $s1  # endereço do buffer de destino
    li $a2, 1      # tamanho do buffer (1 pois estamos fazendo leitura byte a byte)
    syscall       # lê o próximo byte do arquivo
    
    #o número de casas decimais fica salvo em $t3
    # Ler um caractere da sequência de caracteres
    lb $t1, 0($a1)
    
    # Verificar se chegou ao final da sequência
    beqz $v0, finalLinha
    
    #verificar se é virgula 
    li $t2, 44
    beq $t1, $t2, proximoNumero #aqui preciso alterar para salvar o número atual em um registrador e começar a leitura do próximo
    
    #atualizar a parte decimal
    addi $t3, $t3, 1    #atualiza o núemro de casas decimais
    li $t2, 48          # ASCII '0'
    sub $t1, $t1, $t2   # Subtrai '0' do caractere para obter o valor inteiro
    li $t2, 0           #coloco 0 em t2 para controlar quantas vezes devo dividr o número decimal por 10
    mtc1 $t1, $f0       # Carrega o valor inteiro na parte inteira de $f0 para ser dividido
    cvt.s.w $f0, $f0    #remove o resto que surge por causa da transformação
    jal divideDecimal 
    add.s $f12, $f12, $f0 # Adiciona o dígito ao valor
    j continueDecimal
    
    
loopInteiroXtest:
    # ler um byte
    li $v0, 14     # syscall para ler do arquivo
    move $a0, $s5  # descritor do arquivo está em $s5
    move $a1, $s1  # endereço do buffer de destino
    li $a2, 1      # tamanho do buffer (1 pois estamos fazendo leitura byte a byte)
    syscall       # lê o próximo byte do arquivo
    beqz $v0, finalizarArquivoTrain
    lb $t1, 0($a1)
    # Verificar se chegou ao final da sequência
    li $t2, 13              #ascii char (ch)
    beq $t1, $t2, oitavoNumeroTrain
    # Se o próximo caractere for 10 ascii (nl) vai para a próxima linha, então vou  retornar para essa mesma função
    li $t2, 10
    beq $t1, $t2, loopInteiroXtest
    
    # Verificar se o caractere é um ponto decimal
    li $t2, 46          # ASCII '.'
    beq $t1, $t2, continueDecimalXtest # Se for um ponto decimal, vá para pular ponto e começa a leitura da parte decimal a partir do próximo byte
    
    #verificar se é virgula 
    li $t2, 44
    beq $t1, $t2, proximoNumeroTrain
    
    #atualiza a parte inteira
    li $t2, 48          # ASCII '0'
    sub $t1, $t1, $t2   # Subtrai '0' do caractere para obter o valor inteiro
    mul.s $f12, $f12, $f4 # Multiplica o valor atual por 10
    mtc1 $t1, $f0       # Carrega o valor inteiro na parte inteira de $f0
    cvt.s.w $f0, $f0  #remove o resto que surge por causa da transformação
    add.s $f12, $f12, $f0 # Adiciona o dígito ao valor
    j continueXtest
    
    
loopDecimalXtest:
 
    # ler um byte
    li $v0, 14     # syscall para ler do arquivo
    move $a0, $s5  # descritor do arquivo está em $s0
    move $a1, $s1  # endereço do buffer de destino
    li $a2, 1      # tamanho do buffer (1 pois estamos fazendo leitura byte a byte)
    syscall       # lê o próximo byte do arquivo
    
    #o número de casas decimais fica salvo em $t3
    # Ler um caractere da sequência de caracteres
    lb $t1, 0($a1)
    
    # Verificar se chegou ao final da sequência
    li $t2, 13              #ascii char (ch)
    beq $t1, $t2, oitavoNumeroTrain
    beqz $v0, finalizarArquivoTrain
    
    #verificar se é virgula 
    li $t2, 44
    beq $t1, $t2, proximoNumeroTrain #aqui preciso alterar para salvar o número atual em um registrador e começar a leitura do próximo
    
    #atualizar a parte decimal
    addi $t3, $t3, 1    #atualiza o núemro de casas decimais
    li $t2, 48          # ASCII '0'
    sub $t1, $t1, $t2   # Subtrai '0' do caractere para obter o valor inteiro
    li $t2, 0           #coloco 0 em t2 para controlar quantas vezes devo dividr o número decimal por 10
    mtc1 $t1, $f0       # Carrega o valor inteiro na parte inteira de $f0 para ser dividido
    cvt.s.w $f0, $f0    #remove o resto que surge por causa da transformação
    jal divideDecimal 
    add.s $f12, $f12, $f0 # Adiciona o dígito ao valor
    j continueDecimalXtest
    
continue:
    # Avança para o próximo caractere e itera
    j loopInteiro
    
continueDecimal:
    j loopDecimal      #após pular o ponto vamos para a parte que trata os decimais
    
continueXtest:
    # Avança para o próximo caractere e itera
    j loopInteiroXtest
    
continueDecimalXtest:
    j loopDecimalXtest      #após pular o ponto vamos para a parte que trata os decimais
    
    
divideDecimal:
    beq $t2, $t3, retornar #se o número de vezes que devo dividir por 10 for já igual ao número de casas decimais, volto para o loop anterior
    addi $t2, $t2, 1   #somo 1 para já preparar para a próxima verificação
    div.s $f0, $f0, $f4
    j divideDecimal
   
proximoNumero:
    li $t3, 0
    addi $t7, $t7, 1 #aumenta o número de $t7 que salva quantos números estão sendo lidos
    #ainda preciso pensar como decidir em qual registrador salvar
    #mas nesse caso específico sei o núemro de elementos que tô lendo, então vou improvisar
    beq $t7, 1, primeiroNumero
    beq $t7, 2, segundoNumero
    beq $t7, 3, terceiroNumero
    beq $t7, 4, quartoNumero
    beq $t7, 5, quintoNumero
    beq $t7, 6, sextoNumero
    beq $t7, 7, setimoNumero
    beq $t8, 8, oitavoNumero
    
proximoNumeroTrain:
    li $t3, 0
    addi $t7, $t7, 1 #aumenta o número de $t7 que salva quantos números estão sendo lidos
    #ainda preciso pensar como decidir em qual registrador salvar
    #mas nesse caso específico sei o núemro de elementos que tô lendo, então vou improvisar
    beq $t7, 1, primeiroNumeroTrain
    beq $t7, 2, segundoNumeroTrain
    beq $t7, 3, terceiroNumeroTrain
    beq $t7, 4, quartoNumeroTrain
    beq $t7, 5, quintoNumeroTrain
    beq $t7, 6, sextoNumeroTrain
    beq $t7, 7, setimoNumeroTrain
    beq $t8, 8, oitavoNumeroTrain
    
primeiroNumero:
    add.s $f20, $f12, $f31
    lwc1 $f12, zero        #após salvar o número, reseto o $f12
    j continue

segundoNumero:
    add.s $f21, $f12, $f31
    lwc1 $f12, zero        #após salvar o número, reseto o $f12
    j continue

terceiroNumero:
    add.s $f22, $f12, $f31
    lwc1 $f12, zero        #após salvar o número, reseto o $f12
    j continue 
    
quartoNumero:
    add.s $f23, $f12, $f31
    lwc1 $f12, zero        #após salvar o número, reseto o $f12
    j continue

quintoNumero:
    add.s $f24, $f12, $f31
    lwc1 $f12, zero        #após salvar o número, reseto o $f12
    j continue

sextoNumero:
    add.s $f25, $f12, $f31
    lwc1 $f12, zero        #após salvar o número, reseto o $f12
    j continue
    
setimoNumero:
    add.s $f26, $f12, $f31
    lwc1 $f12, zero        #após salvar o número, reseto o $f12
    j continue
    
oitavoNumero:
    add.s $f27, $f12, $f31
    lwc1 $f12, zero        #após salvar o número, reseto o $f12
    j finalLinha
    
primeiroNumeroTrain:
    sub.s $f10, $f20, $f12
    lwc1 $f12, zero
    abs.s $f10, $f10
    j continueXtest

segundoNumeroTrain:
    sub.s $f11, $f21, $f12
    lwc1 $f12, zero
    abs.s $f11, $f11
    j continueXtest
    
terceiroNumeroTrain:
    sub.s $f13, $f22, $f12
    lwc1 $f12, zero
    abs.s $f13, $f13
    j continueXtest
    
quartoNumeroTrain:
    sub.s $f14, $f23, $f12
    lwc1 $f12, zero
    abs.s $f14, $f14
    j continueXtest
    
quintoNumeroTrain:
    sub.s $f15, $f24, $f12
    lwc1 $f12, zero
    abs.s $f15, $f15
    j continueXtest
    
sextoNumeroTrain:
    sub.s $f16, $f25, $f12
    lwc1 $f12, zero
    abs.s $f16, $f16
    j continueXtest
    
setimoNumeroTrain:
    sub.s $f17, $f26, $f12
    lwc1 $f12, zero
    abs.s $f17, $f17
    j continueXtest
    
oitavoNumeroTrain:
    sub.s $f18, $f27, $f12
    lwc1 $f12, zero
    abs.s $f18, $f18
    j finalLinhaTrain
    
    
finalLinhaTrain:
    addi $s4, $s4, 1       #$s5 vai guardar o valor da linha atual para atualizarmos depois
    add $t7, $zero, $zero #zerar o $t7 para podermos voltar a atualizar os números
    jal somaDistancias
    jal salvaMenorDistancia
    j continueXtest
    
    
somaDistancias: 
    #nessa função iremos salvar os valores das distâncias que foram calculados para a linha atual para comparar com a menor distância até o momento.
    #antes de fazer as somas é de bom tom zerar os registradores
    add.s $f0, $f31, $f31
    add.s $f1, $f31, $f31
    add.s $f2, $f31, $f31
    add.s $f3, $f31, $f31
    add.s $f5, $f31, $f31
    add.s $f6, $f31, $f31
    
    #com todos os registradores zerados vamos somar
    add.s $f0, $f10, $f11
    add.s $f1, $f13, $f14
    add.s $f2, $f15, $f16
    add.s $f3, $f17, $f18
    add.s $f5, $f0, $f1
    add.s $f6, $f2, $f3
    add.s $f0, $f6, $f5
    
    
    #em seguida vou zerar os regsitradores que estão guardando os valores porque parece estar com alguma sujeira na hora das subtraçoes
    add.s $f10, $f31, $f31
    add.s $f11, $f31, $f31
    add.s $f13, $f31, $f31
    add.s $f14, $f31, $f31
    add.s $f15, $f31, $f31
    add.s $f16, $f31, $f31
    add.s $f17, $f31, $f31
    add.s $f18, $f31, $f31
    jr $ra

   
salvaMenorDistancia:
    c.lt.s $f0, $f30                     #verifica o número que já está salvo com a menor distância e compara com o resultado da soma anterior, se a soma for menor, atualiza, se não avalia o próximo número
    bc1t atualizarMenorDistancia
    jr $ra
   
         
finalLinha:
    li $t7, 0
    # ler o próximo byte aqui    
    # Avança para o próximo caractere e itera
    addi $t0, $t0, 1
    add $a0, $a0, 1
    li $v0, 14     # syscall para ler do arquivo
    move $a0, $s0  # descritor do arquivo está em $s0
    move $a1, $s1  # endereço do buffer de destino
    li $a2, 1      # tamanho do buffer (1 pois estamos fazendo leitura byte a byte)
    syscall       # lê o próximo byte do arquivo
    lb $t1, 0($a1)
    li $t2, 10                   #ascii char (nl) serve para pular linha
    beq $t1, $t2, loopInteiroXtest     #aqui devo começar a leitura do outro arquivo para fazer a comparação
    j encerrarPrograma
   
retornar:
   jr $ra    #retorna para o $ra, que foi salvo durante o loop de leitura de decimais
   
verificaProximaLinha:
   #aqui devemos atualizar o número da linha sendo lida do xTrain para podermos salvar qual é a linha que possui a menor distância
   j encerrarPrograma
   
atualizarMenorDistancia:
    #caso a distância da linha atual for menor que a menor distância atual, aqui devemos atualizar o número da linha e o valor da menor distância.
    add.s $f30, $f0, $f31   # $f30 possui o resultado que é a menor distância, $f0 possui o resultado da soma da distância atual, $f31 possui o valor 0
    add $s3, $s4, $zero
    jr $ra
    
finalizarArquivoTrain:
    #aqui devo atualizar o valor de ytrain com o valor correspondente à linha da menor distância em yTest
    addi $t3, $zero, 1   #aqui usarei t3 para contar quantas linhas foram lidas até chegar na linha que deve ser salva
    jal lerYtest
    j encerrarPrograma
    
    
lerYtest:
    beq $t3, $s3, atualizarYtrain
    li $v0, 14     # syscall para ler do arquivo
    move $a0, $s6  # descritor do arquivo está em $s6
    move $a1, $s1  # endereço do buffer de destino
    li $a2, 1      # tamanho do buffer (1 pois estamos fazendo leitura byte a byte)
    syscall        # lê o próximo byte do arquivo
    lb $t1, 0($a1)
    li $t2, 10
    bne $t1, $t2, lerYtest
    addi $t3, $t3, 1

atualizarYtrain:

    li $v0, 14     # syscall para ler do arquivo
    move $a0, $s6  # descritor do arquivo está em $s6
    move $a1, $s1  # endereço do buffer de destino
    li $a2, 1      # tamanho do buffer (1 pois estamos fazendo leitura byte a byte)
    syscall        # lê o próximo byte do arquivo
    lb $t1, 0($a1)
    sb $t1, 0($s7)
    addi $s2, $s2, 1
    addiu $s7, $s7, 1
    beqz $v0, encerrarPrograma
    bne $t1, 10, atualizarYtrain
    j loopInteiro
    
   
encerrarPrograma:
    #aqui posso fechar os outros arquivos, assim abrindo espaço nos registradores tipo s
    
    li $v0, 16 #função para fechar o arquivo, que deve ter o descritor em $a0
    move $a0, $s0
    syscall
    
    li $v0, 16 #função para fechar o arquivo, que deve ter o descritor em $a0
    move $a0, $s5
    syscall
    
    li $v0, 16 #função para fechar o arquivo, que deve ter o descritor em $a0
    move $a0, $s6
    syscall
    
    li $v0, 13                   # syscall de abertura de arquivo
    la $a0, yTrain               # carrega endereço com nome do arquivo para abertura
    li $a1, 1                    # indicador de abertura em modo escrita
    li $a2, 0     		 # ignorar permissões
    syscall       		 # chamada de sistema que realiza a abertura
    move $s0, $v0                # o descritor do arquivo yTrain ficará em s0, quer não está mais sendo utilizado para guardar o descritor de outro arquivo.
    
    li $v0, 15 
    move $a0, $s0
    la $a1, yTrainBuffer
    addi $a2, $s2, 0
    syscall
    
    li $v0, 10
    syscall