# encoding=utf-8
import os
import re
import csv
import sys
from collections import OrderedDict

def Read_File(File_Path):
    warning_dict = OrderedDict()
    error_dict = OrderedDict()
    with open(File_Path,'r') as f_r:
        m = 0
        n = 0
        for lines in f_r.readlines():
            line = lines.strip()
            if line.startswith('Warning'):
                if ' (' not in line:
                    key = 'NO_Type_Warning-{}'.format(m)
                    m += 1
                    warning_dict[key] = '{}##{}'.format(1,line)
                else:
                    key = line.split('(')[-1].split(')')[0]
                    if key not in warning_dict.keys():
                        num_w = 1
                        warning_dict[key] = '{}##{}'.format(num_w,line)
                    else:
                        num_w += 1
                        warning_dict[key] = '{}##{}'.format(num_w,line)
            if line.startswith(('Error', 'Fatal', 'Severe')):
                if '(' not in line:
                    key = 'NO_Type_Error-{}'.format(n)
                    n += 1
                    error_dict[key] = '{}##{}'.format(1,line)
                else:
                    key = line.split('(')[-1].split(')')[0]
                    if key not in error_dict.keys():
                        num_e = 1
                        error_dict[key] = '{}##{}'.format(num_e,line)
                    else:
                        num_e += 1
                        error_dict[key] = '{}##{}'.format(num_e,line) 
    return warning_dict,error_dict



if __name__ == '__main__':
    file_path = sys.argv[1]
    tool = file_path.split('/')[-1].split('.')[0]
    if len(sys.argv) > 2:
        save_path = sys.argv[2]
    else :
        save_path = '.'
    savedb_csv = '{}/{}_Warning_Error_Sum.csv'.format(save_path,tool)
    csvf = open(savedb_csv,'w',encoding='utf-8',newline="")
    csv_writer = csv.writer(csvf)
    warning_dict = OrderedDict()
    error_dict = OrderedDict()
    warning_dict,error_dict = Read_File(file_path)
    csv_writer.writerow(['Type','Num','Description'])
    csv_writer.writerow(['Error','',''])    
    for key in error_dict.keys():
        #print('{}:{}'.format(key,error_dict[key]))
        Type = key
        Num  = error_dict[key].split('##')[0]
        Des  = error_dict[key].split('##')[1]
        csv_writer.writerow([Type,Num,Des])
    csv_writer.writerow(['Warning','',''])
    for key in warning_dict.keys():
        #print('{}:{}'.format(key,warning_dict[key]))
        Type = key
        Num  = warning_dict[key].split('##')[0]
        Des  = warning_dict[key].split('##')[1]
        csv_writer.writerow([Type,Num,Des])
    csvf.close()
    if error_dict:
        print('ERROR: {} contains {} error type(s); see {}'.format(
            file_path, len(error_dict), savedb_csv))
        sys.exit(1)
