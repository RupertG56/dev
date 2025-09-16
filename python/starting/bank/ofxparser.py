from ofxparse import *
import os

def parsemyfile():
    # Load the OFX file
    script_path = os.path.dirname(os.path.abspath(__file__))
    dp = os.path.join(script_path, 'data', 'export.ofx')
    with open(dp, 'r') as f:
        parser = OfxParser.parse(f)

    # Print account information
    print("-----------------------------------------------")
    print(f"Account ID: {parser.account.account_id}")
    print(f"Account Number: {parser.account.number}")
    print(f"Account Type: {parser.account.account_type}")
    print("-----------------------------------------------")
    print("-----------------------------------------------")

    # Iterate over transactions and print details
    total = 0
    deposits = [deposit for deposit in parser.account.statement.transactions if 'PAYROLL' in deposit.memo]
    deposit_total = sum(deposit.amount for deposit in deposits)
    direct_mav_cost = sum(item.amount for item in [x for x in parser.account.statement.transactions if 'MAVERIK U PAY' in x.memo])
    mobile_funds_transfer = sum(item.amount for item in [x for x in parser.account.statement.transactions if 'MOBILE BANKING FUNDS TRANSFER' in x.memo])
    visa_transactions = [x for x in parser.account.statement.transactions if not 'DELL' in x.memo and not 'ACCESS SECURE' in x.memo and 'VISA - ' in x.memo]
    visa_charges = sum(item.amount for item in visa_transactions)
    for transaction in visa_transactions:
        print("-----------------------------------------------")
        print(f"Transaction ID: {transaction.id}")
        print(f"Date: {str(transaction.date)}")
        print(f"Amount: {transaction.amount}")
        print(f"Description: {transaction.memo}")
        print("-----------------------------------------------")
        if transaction.amount < 0 and 'MAVERIK' in transaction.payee:
            total += transaction.amount

    print(f"Deposit Total: {deposit_total}")
    print(f"Direct Mav Cost: {direct_mav_cost}")
    print(f"Mobile Funds Transfer: {mobile_funds_transfer}")
    print(f"Visa Charges: {visa_charges}")

parsemyfile()