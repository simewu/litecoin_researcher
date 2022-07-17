from blockchain_parser.blockchain import Blockchain
import csv
import json, os, sys, datetime, re
import plyvel
import time


bitcoinPath = ''
if os.path.exists('/media/sf_Bitcoin/blocks'):
	bitcoinPath = '/media/sf_Bitcoin' # Virtual machine shared folder
elif os.path.exists('/media/sf_BitcoinVictim/blocks'):
	bitcoinPath = '/media/sf_BitcoinVictim'
elif os.path.exists('/media/sf_BitcoinAttacker/blocks'):
	bitcoinPath = '/media/sf_BitcoinAttacker'
elif os.path.exists(f'/media/{os.getlogin()}/BITCOIN/blocks'):
	bitcoinPath = f'/media/{os.getlogin()}/BITCOIN'
elif os.path.exists(f'/media/{os.getlogin()}/Blockchains/Bitcoin/blocks'):
	bitcoinPath = f'/media/{os.getlogin()}/Blockchains/Bitcoin'
elif os.path.exists(f'/media/{os.getlogin()}/Long Term Storage/Bitcoin/blocks'):
	bitcoinPath = f'/media/{os.getlogin()}/Long Term Storage/Bitcoin'


bitcoinBlocksPath = os.path.join(bitcoinPath, 'blocks')
bitcoinTxIndexesPath = os.path.join(bitcoinPath, 'indexes/txindex')

outputDatabaseFileName = os.path.expanduser(os.path.join('~', 'Desktop', 'Bitcoin Transaction Database.csv'))
outputMappingFileName = os.path.expanduser(os.path.join('~', 'Desktop', 'Bitcoin Transaction Mapping Addresses.csv'))

startHeight = 0
endHeight = 744578

if not os.path.exists(bitcoinBlocksPath):
	print(bitcoinBlocksPath + ' does not exist.')
	sys.exit()

blockchain = Blockchain(os.path.expanduser(bitcoinBlocksPath))
db = plyvel.DB(bitcoinTxIndexesPath, compression=None)

epoch = datetime.datetime.utcfromtimestamp(0)
counter = 0

addressMap = {}
addressMapCount = 0
sessionResumed = False

def resumeSession():
	global outputDatabaseFileName, outputMappingFileName, counter, addressMap, addressMapCount, sessionResumed

	print('    Resuming address mapping...')
	addressMapFile = open(outputMappingFileName, 'r')
	addressMapReader = csv.reader(addressMapFile)
	header = next(addressMapReader)
	for row in addressMapReader:
		addressMap[row[1]] = int(row[0])
		addressMapCount += 1
	addressMapFile.close()

	print('    Reading database to get last line...')
	with open(outputDatabaseFileName, 'rb') as file:
		try:
			file.seek(-2, os.SEEK_END)
			while file.read(1) != b'\n':
				file.seek(-2, os.SEEK_CUR)
		except OSError:
			file.seek(0)
		lastLine = file.readline().decode()

	lastBlockHeight = lastLine.split(',')[1]
	print('    Block height to resume:', lastBlockHeight)
	# We want to break early in case the block height isn't an int
	lastBlockHeightInt = int(lastBlockHeight)

	tempFileName = outputDatabaseFileName[:-4] + '_TEMP.csv'
	os.replace(outputDatabaseFileName, tempFileName)

	prev_output = open(tempFileName, 'r')
	output = open(outputDatabaseFileName, 'w+')

	# Removing all old remnants of the last block height so that we can start writing to it fresh
	print('    Re-writing database minus the last block height...')
	line = prev_output.readline()
	while line:
		blockHeight = line.split(',')[1]

		if blockHeight == lastBlockHeight:
			break

		output.write(line)
		line = prev_output.readline()

	counter = lastBlockHeightInt - 1

	prev_output.close()
	output.close()
	os.remove(tempFileName)
	sessionResumed = True
	return lastBlockHeightInt


output = None
outputAddressMap = None
if os.path.exists(outputDatabaseFileName) and os.path.exists(outputMappingFileName):
	resume = input('Previous session found, resume it? (y/n): ').lower() in ['y', 'yes']
	if resume == False:
		confirm = input('Are you sure you\'d like to overwrite this session? (y/n): ').lower() in ['y', 'yes']

		if confirm == False:
			print('Goodbye.')
			sys.exit()

		output = open(outputDatabaseFileName, 'w+')
		outputAddressMap = open(outputMappingFileName, 'w+')
		outputAddressMap.write('Primary Key,Address,\n')

	else:
		print('Resuming session...')
		try:
			startHeight = resumeSession()
		except Exception as e:
			print('Failed to resume:', e)
			sys.exit()
		output = open(outputDatabaseFileName, 'a+')
		outputAddressMap = open(outputMappingFileName, 'a+')

		print('Successfully resumed session to block height', startHeight)
		time.sleep(5)
		print('Beginning in five seconds...')
		time.sleep(5)
else:
	output = open(outputDatabaseFileName, 'w+')
	outputAddressMap = open(outputMappingFileName, 'w+')
	outputAddressMap.write('Primary Key,Address,\n')



def mapAddress(address):
	if address == '*': return '*'
	global addressMap, addressMapCount
	if address in addressMap:
		return addressMap[address]
	addressMap[address] = addressMapCount
	outputAddressMap.write(f'{addressMap[address]},{address},\n')
	addressMapCount += 1
	return addressMap[address]

def dumpBlock(block):
	lines = ''

	for tx in block.transactions:

		txInputAddresses = ''
		txOutputAddresses = ''

		inputValueSum = 0
		outputValueSum = 0
		youngestAddressIndex = None

		if tx.is_coinbase():
			txInputAddresses = 'COINBASE'

		else:
			for _input in tx.inputs:
				inputHash = _input.transaction_hash
				inputIndex = _input.transaction_index

				try:
					oldtx = blockchain.get_transaction(inputHash, db)
					oldtxoutput = oldtx.outputs[inputIndex]
					addresses = oldtxoutput.addresses
					address = ''
					value = oldtxoutput.value
					if len(addresses) < 1:
						address = '*'
						print('INVALID TRANSACTION INPUT')
						print('    TX ' + inputHash)
						print('    TX Output[' + str(inputIndex) + ']')
					elif len(addresses) > 1:
						print('MULTIPLE TRANSACTION INPUTs')
						print('    TX ' + inputHash)
						print('    TX Input[' + str(inputIndex) + ']')

						address = '['
						for a in range(len(addresses)):
							address += str(addresses[a].address)
							if a != len(addresses) - 1:
								address += ','
						address += ']'
					else:
						address = str(addresses[0].address)
				except:
					address = '*'
					value = '*'

				if address == '*' and value == 0:
					continue # Skip OP_RETURN 0

				addressIndex = mapAddress(address)
				inputValueSum += value
				if addressIndex != '*' and (youngestAddressIndex == None or youngestAddressIndex < addressIndex):
					youngestAddressIndex = addressIndex
				txInputAddresses += str(addressIndex) + ':' + str(value) + ' '

			txInputAddresses = txInputAddresses.strip()
		# print('Inputs: ', txInputAddresses)

		outputHash = tx.txid
		outputIndex = 0
		for _output in tx.outputs:
			addresses = _output.addresses
			address = ''
			value = _output.value
			if len(addresses) < 1:
				if value == 0: continue
				address = '*'
			elif len(addresses) > 1:
				print('MULTIPLE TRANSACTION OUTPUTs')
				print('    TX ' + outputHash)
				print('    TX Output[' + str(outputIndex) + ']')

				address = '['
				for a in range(len(addresses)):
					address += str(addresses[a].address)
					if a != len(addresses) - 1:
						address += ','
				address += ']'
			else:
				address = str(addresses[0].address)

			if address == '*' and value == 0:
				continue # Skip OP_RETURN 0

			addressIndex = mapAddress(address)
			outputValueSum += value
			if addressIndex != '*' and (youngestAddressIndex == None or youngestAddressIndex < addressIndex):
				youngestAddressIndex = addressIndex
			txOutputAddresses += str(addressIndex) + ':' + str(value) + ' '
			outputIndex += 1

		txOutputAddresses = txOutputAddresses.strip()
		#print('Outputs: ', txOutputAddresses)


		line = ''
		line += str((block.header.timestamp - epoch).total_seconds()) + ','
		line += str(block.height) + ','
		line += str(tx.txid) + ','
		line += txInputAddresses + ','
		line += txOutputAddresses + ','
		line += str(inputValueSum) + ','
		line += str(outputValueSum) + ','
		line += str(youngestAddressIndex) + ','

		lines += line + '\n'

	return lines

if sessionResumed == False:
	line = 'Time Epoch,Block Height,TX ID,Inputs,Outputs,Sum Input Values,Sum Output Values,Youngest Address Index,'
	output.write(line + '\n')

lastFlushTime = time.time() - 60
for block in blockchain.get_ordered_blocks(os.path.expanduser(os.path.join(bitcoinBlocksPath + 'index')), start=startHeight, end=endHeight, cache='index-cache.pickle'):
	#print(dir(block))
	#print(block.blk_file)
	#sys.exit()

	now = time.time()
	if now - lastFlushTime >= 10: # Flush the files every 10 seconds
		output.flush()
		outputAddressMap.flush()
		print('Block ' + str(counter) + '\t' + str(10 * counter / (endHeight - startHeight)) + '% Complete')
		time.sleep(0.1)
		lastFlushTime = now

	lines = dumpBlock(block)
	if(lines):
		output.write(lines)

	counter += 1
		
db.close()
output.close()
print('Ok.')
