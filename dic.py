from multiprocessing import Pool
from functools import partial
import time
import sys
import os

maximum = 0
procs = 4
fatias = 0
alfabeto = 'abcdefghijklmnopqrstuvwxyz012345'
c = 8      #numero de caracteres
b = 5      #bits por caracter
r = 1 << b #tamanho do alfabeto (32-bits)
n = b*c    #bits por senha (40-bits quando c=8)
palavra_codificada = '' #Declaracao global para ficar mais facil de usar map
tabela_c = []   #mesma coisa pra tabela_c
comuns_c = []

def forcabruta(i):
    fim = i+fatias-1
    if (fim >= maximum):
        fim=maximum-1
    print 'fim',fim
    while True:
        senha_b = ''
        for s in comuns_c[i]:
            senha_b += bin(s)[2:].zfill(5)
        tentativa_cifrada = cifrar(senha_b,tabela_c)
        # if (tentativa_cifrada == palavra_codificada):
        #     print "Achei!"
        #     print decodificar(comuns_c[i])
        #     return comuns_c[i]
        # elif (i == fim):
        #     print 'Processo nao achou'
        #     return 0
        if (tentativa_cifrada == palavra_codificada):
            print palavra_codificada
            print "Achei!"
            print decodificar(comuns_c[i])
            return decodificar(comuns_c[i])
        elif (i == fim):
            print 'Processo nao achou'
            return '0'
        i+=1

def codificar(palavra):
    codes = []
    for i in range(len(palavra)):
        codes.append(alfabeto.find(palavra[i]))
    return codes

def decodificar(codes):
    palavra = ''
    for i in xrange(0,len(codes)):
        palavra += alfabeto[codes[i]]

    return palavra

def cifrar(senha_b, tabela):
    aux_t = []
    res = [0]*c
    for i in range(len(senha_b)):
        linha = ''
        for item in tabela[i]:
            linha = linha + '{0:2d} '.format(item)

        if senha_b[i] == '1':
            aux_t.append(tabela[i])

    for t in aux_t:
        carry = 0
        for i in range(c-1,-1,-1):
            tmp = (res[i] + t[i] + carry) % r #r == 32
            carry = (res[i] + t[i] + carry) >= r
            res[i] = tmp
    return res

def main():
    start = time.time()
    senha_criptografada = sys.argv[1].rstrip('\n')
    arquivo = sys.argv[2]
    wordlist = sys.argv[3]
    print '--------------------------------------------------------------------'
    print 'Texto-Fechado: ', senha_criptografada.rjust(19)
    with open(arquivo,'r') as f:
        tabela = f.readlines()

    global tabela_c
    for i in range(len(tabela)):
        tabela[i] = tabela[i].rstrip('\n')
        tabela_c.append(codificar(tabela[i]))

    with open(wordlist,'r') as g:
        comuns = g.readlines()

    global maximum
    maximum = len(comuns)
    global fatias
    print 'procs', procs
    fatias = (maximum/procs)+1
    print 'fatia', fatias
    print maximum
    for i in range(len(comuns)):
        comuns[i] = comuns[i].rstrip('\n')
        comuns_c.append(codificar(comuns[i][:-1]))

    global palavra_codificada
    palavra_codificada = codificar(senha_criptografada)

    comecos = range(0, maximum, fatias)
    print 'comecos', comecos
    print 'Cada processo fara', fatias, 'palavras aproximadamente.'
    pool = Pool(procs)
    crack_combo = pool.map(partial(forcabruta), comecos)
    pool.close()
    print '>',crack_combo
    for index, item in enumerate(crack_combo):
        if len(str(item)) == 8:
            crackeada = item
    texto_aberto = ''
    # for i in range(0, len(crackeada), 5):
    #     s = crackeada[i] + crackeada[i+1] + crackeada[i+2] + crackeada[i+3] + crackeada[i+4]
    #     texto_aberto += alfabeto[int(s, 2)]
    print '--------------------------------------------------------------------'
    print 'Texto-Aberto: ', texto_aberto.rjust(20)
    print '--------------------------------------------------------------------'
    elapsed_time = time.time() - start
    print "Tempo de quebra:           {}".format(elapsed_time)

if __name__ == "__main__":
    main()
