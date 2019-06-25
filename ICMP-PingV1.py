#!/usr/bin/python3
# -*- coding: utf-8 -*-
# Technical support: https://www.jianshu.com/u/69f40328d4f0 
# Technical support https://china-testing.github.io/
# https://github.com/china-testing/python-api-tesing/blob/master/practices/ping.py
# Discuss nail free group 21745728 qq q group 144081101 567351477
# CreateDate: 2018-11-22

import os 
import argparse 
import socket
import struct
import select
import time
import sys


ICMP_ECHO_REQUEST = 8 # Platform specific
DEFAULT_TIMEOUT = 2
DEFAULT_COUNT = 4 

# Dictionary to lookup the index of alphabets
dict1 = {'A' : 1, 'B' : 2, 'C' : 3, 'D' : 4, 'E' : 5,
'F' : 6, 'G' : 7, 'H' : 8, 'I' : 9, 'J' : 10,
'K' : 11, 'L' : 12, 'M' : 13, 'N' : 14, 'O' : 15,
'P' : 16, 'Q' : 17, 'R' : 18, 'S' : 19, 'T' : 20,
'U' : 21, 'V' : 22, 'W' : 23, 'X' : 24, 'Y' : 25, 'Z' : 26}

# Dictionary to lookup alphabets
# corresponding to the index after shift
dict2 = {0 : 'Z', 1 : 'A', 2 : 'B', 3 : 'C', 4 : 'D', 5 : 'E',
6 : 'F', 7 : 'G', 8 : 'H', 9 : 'I', 10 : 'J',
11 : 'K', 12 : 'L', 13 : 'M', 14 : 'N', 15 : 'O',
16 : 'P', 17 : 'Q', 18 : 'R', 19 : 'S', 20 : 'T',
21 : 'U', 22 : 'V', 23 : 'W', 24 : 'X', 25 : 'Y'}


class Pinger(object):
    """ Pings to a host -- the Pythonic way"""

    def __init__(self, target_host, message_cryp, count=DEFAULT_COUNT, timeout=DEFAULT_TIMEOUT):
        self.target_host = target_host
        self.message_cryp = message_cryp
        self.count = count
        self.timeout = timeout


    def do_checksum(self, source_string):
        """  Verify the packet integritity """
        sum = 0
        max_count = (len(source_string)//2)*2
        #max_count = len(source_string)
        count = 0
        while count < max_count :   
            val = source_string[count + 1]*256 + source_string[count]                   
            sum = sum + val
            sum = sum & 0xffffffff 
            count = count + 2

        if max_count<len(source_string):
            sum = sum + (source_string[len(source_string) - 1])
            #sum = sum & 0xffffffff 
        sum &= 0xffffffff
        sum = (sum >> 16)  +  (sum & 0xffff)
        sum = sum + (sum >> 16)
        answer = ~sum
        answer = answer & 0xffff
        answer = socket.htons(answer)
        #answer = answer >> 8 | (answer << 8 & 0xff00)
        return answer
      

    def receive_pong(self, sock, ID, timeout):
        """
        Receive ping from the socket.
        """
        time_remaining = timeout
        while True:
            start_time = time.time()
            readable = select.select([sock], [], [], time_remaining)
            time_spent = (time.time() - start_time)
            if readable[0] == []: # Timeout
                return

            time_received = time.time()
            recv_packet, addr = sock.recvfrom(1024)
            icmp_header = recv_packet[20:28]
            type, code, checksum, packet_ID, sequence = struct.unpack(
       "bbHHh", icmp_header
   )
            if packet_ID == ID:
                bytes_In_double = struct.calcsize("d")
                time_sent = struct.unpack("d", recv_packet[28:28 + bytes_In_double])[0]
                return time_received - time_sent

            time_remaining = time_remaining - time_spent
            if time_remaining <= 0:
                return


    def send_ping(self, sock,  ID):
        """
        Send ping to the target host
        """
        target_addr  =  socket.gethostbyname(self.target_host)

        my_checksum = 0

        # Create a dummy heder with a 0 checksum.
        header = struct.pack("bbHHh", ICMP_ECHO_REQUEST, 0, my_checksum, ID, 1)
        #bytes_In_double = struct.calcsize("d")
        # Data sent in ping pack
        #data = (192 - bytes_In_double) * "Q"
        #data = "ale efofa"
        data = self.message_cryp
        data = struct.pack("d", time.time()) + bytes(data.encode('utf-8'))

        # Get the checksum on the data and the dummy header.
        print (header + data)
        my_checksum = self.do_checksum(header + data)
        header = struct.pack(
      "bbHHh", ICMP_ECHO_REQUEST, 0, socket.htons(my_checksum), ID, 1
  )
        packet = header + data
        sock.sendto(packet, (target_addr, 1))


    def ping_once(self):
        """
        Returns the delay (in seconds) or none on timeout.
        """
        icmp = socket.getprotobyname("icmp")
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_RAW, icmp)
        except socket.error as e:
            if e.errno == 1:
                # Not superuser, so operation not permitted
                e.msg +=  "ICMP messages can only be sent from root user processes"
                raise socket.error(e.msg)
        except Exception as e:
            print ("Exception: %s" %(e))

        my_ID = os.getpid() & 0xFFFF

        self.send_ping(sock, my_ID)
        delay = self.receive_pong(sock, my_ID, self.timeout)
        sock.close()
        return delay


    def ping(self):
        """
        Run the ping process
        """
        for i in range(self.count):
            print ("Ping to %s..." % self.target_host,)
            try:
                delay  =  self.ping_once()
            except socket.gaierror as e:
                print ("Ping failed. (socket error: '%s')" % e[1])
                break

            if delay  ==  None:
                print ("Ping failed. (timeout within %ssec.)" % self.timeout)
            else:
                delay  =  delay * 1000
                print ("Get pong in %0.4fms" % delay)

#################### Encrypt Message ###########################
################################################################

# Function to encrypt the string
# according to the shift provided

def encrypt(message, shift):
	cipher = ''
	for letter in message:
		# checking for space
		if(letter != ' '):
		# looks up the dictionary and
		# adds the shift to the index
			num = ( dict1[letter] + shift ) % 26
			# looks up the second dictionary for
			# the shifted alphabets and adds them
			cipher += dict2[num]
		else:
			# adds space 
			cipher += ' '
	return cipher

def messageCryp(message, shift):
	#DIALOG message = input("Digite uma mensagem: ")
	#DIALOG shift = int(input("Digite um valor de shift: "))

        result = encrypt(message.upper(), shift)
	#print ("\nMensagem criptografada: " + result)
    #message = result
	#result = decrypt(message.upper(), shift)
	#print ("Mensagem decriptografada: " + result)
        return result
################################################################



if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Python ping')
    parser.add_argument('--Message', action="store", help='Message to send')
    parser.add_argument('--Shift', action="store", help='Host Name or IP')
    parser.add_argument('--Host', action="store", help='Host Name or IP')
    given_args = parser.parse_args()  
    target_host = given_args.Host
    shift = int(given_args.Shift)
    message = given_args.Message
    message_cryp = messageCryp(message, shift)
    pinger = Pinger(target_host=target_host, message_cryp=message_cryp)
    pinger.ping()
