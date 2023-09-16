from ftplib import FTP
import zipfile
import pandas as pd
import os

ftp_url = '127.0.0.1'
ftp_user = 'ola'
ftp_password = 'test'
file_name = 'Case_Study_202309_Data.zip'
extract_dir = "Proccessor/"
try:
    # Connect to the FTP Server [ local FTP Server - XAMMP ]
    ftp = FTP(ftp_url)
    ftp.login(ftp_user, ftp_password)

    # Fetch and the file and download it
    with open(file_name, 'wb') as local_file:
        ftp.retrbinary('RETR ' + file_name, local_file.write)

    ftp.quit()

    # Extract the zip file to the PRoccessor folder
    with zipfile.ZipFile(file_name, 'r') as zip_ref:
        zip_ref.extractall(extract_dir)

    files = os.listdir(path=f"{extract_dir}/Case_Study_Data_For_Share/")
    columns = ['Row ID', 'Order ID', 'Order Date', 'Ship Date', 'Ship Mode',
               'Customer ID', 'Customer Name', 'Segment', 'Country', 'City', 'State',
               'Postal Code', 'Region', 'Product ID', 'Category', 'Sub-Category',
               'Product Name', 'Sales', 'Quantity', 'Discount', 'Profit']
    with open('output.txt', mode='a+', encoding='UTF-8') as file:
        header = ""
        for col in columns:
            header = header + col + '|'
        file.write(header)
        file.write('\n')

    for filename in files:
        data = pd.read_csv(
            f"{extract_dir}/Case_Study_Data_For_Share/{filename}", encoding='ansi', sep='|')

        for d in data.index:
            text = ""
            for col in columns:
                try:
                    text = text + str(data[col][d]) + '|'
                except: 
                    text = text + '|'
                    print(f"{extract_dir}/Case_Study_Data_For_Share/{filename}")
            with open('output.txt', mode='a+', encoding='UTF-8') as file:
                file.write(text)
                file.write('\n')


except Exception as e:
    print(f"Error: {e}")
