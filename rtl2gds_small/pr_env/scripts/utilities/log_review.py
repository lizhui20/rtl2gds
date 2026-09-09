# encoding=utf-8
import os
import re
import csv
import sys
from collections import OrderedDict

WARNING_EXPLANATIONS = [
    (re.compile(r'\b(TECH-026|TECH-073|DPUI-924|NEX-001|PDC-003|ZRT-02[56])\b'),
     'PDK technology-file modeling warning; explain with the foundry tech-file/routing-layer definition.'),
    (re.compile(r'\b(SQM-1067)\b'),
     'Scan-cell remap warning; acceptable when scan cells are already fixed in the DFT output netlist.'),
    (re.compile(r'\b(CSTR-011|CSTR-101)\b'),
     'Constraint/SDC modeling warning; acceptable when final timing reports are clean and the affected clock/constraint is reviewed.'),
    (re.compile(r'\b(PGR-095)\b'),
     'Power-grid via-rule warning; review if PG DRC/connectivity is not clean.'),
    (re.compile(r'\b(CHF-011|CHF-014|CHF-073|LGL-025)\b'),
     'Chip-finish/filler-library warning; explain with filler cell attributes and final legality/DRC reports.'),
    (re.compile(r'max_legality_.*ignored|Exclusive bound .* has no cells'),
     'FC legalization reporting warning; acceptable when final legality and route checks are clean.'),
    (re.compile(r'\b(TIM-204|ROPT-002|OPT-209)\b'),
     'Timing/optimization warning; review QoR, constraints, and PT signoff before waiving.'),
    (re.compile(r'\b(ZRT-301|ZRT-302|ZRT-311)\b'),
     'FC antenna pre-check warning; acceptable only when the foundry Calibre antenna deck is run and reports zero real antenna violations.'),
    (re.compile(r'Multiply .* derates are skipped'),
     'FC SDC write warning for unsupported multiplicative derate export; acceptable when final PT signoff reads the intended libraries/SPEFs and timing is clean.'),
    (re.compile(r'\b(UITE-305|UITE-315|RC-009)\b'),
     'PrimeTime modeling warning; acceptable only if parasitic annotation and final timing are clean.'),
    (re.compile(r'\b(RC-011)\b'),
     'PrimeTime library extrapolation warning; review transition constraints/library range, acceptable only with clean final timing and no annotation gaps.'),
    (re.compile(r'\b(SEL-003)\b'),
     'PrimeTime object-selection warning; acceptable for optional supply objects when timing/parasitic checks are clean.'),
    (re.compile(r'\b(PTE-003)\b'),
     'PrimeTime disabled timing-arc warning from loops/constants; review report_disable_timing if timing coverage is in doubt.'),
    (re.compile(r'\b(PARA-180)\b'),
     'PrimeTime SPEF corner-name mismatch notice from re-reading setup/hold parasitics in one session; acceptable when the requested cworst/cbest SPEFs are read and annotation reports are clean.'),
    (re.compile(r'\b(GRD-0439)\b|TLUPlus file name is not provided'),
     'StarRC grdgen technology-generation warning; acceptable if the final .nxtgrd is created and StarRC extraction succeeds.'),
    (re.compile(r'\b(SX-2064)\b'),
     'StarRC via-definition warning; fix by adding the missing DEF/LEF via to the StarRC tech LEF before treating extraction as clean.'),
    (re.compile(r'\b(SX-0290|SX-0291)\b|HALF_NODE_SCALE_FACTOR'),
     'StarRC NXTGRD half-node scaling notice; expected for this N28 grid and acceptable when SPEF generation succeeds.'),
    (re.compile(r'\b(SX-1851|SX-2076)\b'),
     'StarRC abstract-LEF layer connectivity warning; acceptable for unused upper/RDL/contact layers when xTract, report violations, and SPEF generation are clean.'),
    (re.compile(r'\b(SX-2105|SX-3860|SX-4032)\b|INPUT_NAMES_ESCAPE_REMOVAL'),
     'StarRC runtime/reporting warning; does not change extraction results when the run completes and reports zero task errors.'),
    (re.compile(r'\b(EX-414)\b|found open net'),
     'StarRC open-net report; review opens.sum and document only intentional unconnected abstract-cell/internal pins or unused nets.'),
    (re.compile(r'unlinked power cell|guide_environment'),
     'Formality setup/library warning; acceptable only if compare verifies successfully.'),
	(re.compile(r'Redefining clock'),
	 'Repeated SDC read warning during ECO/check stages; acceptable when final timing uses the intended clock definition.'),
	(re.compile(r'\b(ZRT-113)\b|unused floating user-enter shapes'),
	 'Router cleanup warning for unused user-entered shapes; acceptable only when final check_routes reports zero DRC/open nets.'),
	(re.compile(r'No module declaration for module'),
	 'v2lvs logical Verilog black-box warning; acceptable for standard cells when the matching CDL subckt library is supplied and Calibre LVS is CORRECT.'),
	(re.compile(r'Duplicate subckt definition'),
	 'Foundry CDL library duplicate-definition warning; acceptable when Calibre resolves the library and LVS reports CORRECT with matched instance/device counts.'),
	(re.compile(r'POWER, GROUND, LABELED or TEXT nets required by ERC operations do not exist'),
	 'Calibre ERC side warning from block-level LVS port handling; acceptable for this block run when LVS is CORRECT and top-level port recognition is documented separately.'),
	    (re.compile(r'There is no data for layout net name'),
	     'Calibre ERC optional power/ground-name warning; expected when the foundry deck enumerates unused supply aliases for a block that only uses VDD/VSS.'),
	    (re.compile(r'Layer \d+ contains unmapped objects and is the source layer of LAYER MAP'),
	     'Calibre layer-purpose warning from optional/non-LVS purpose datatypes in the foundry deck; acceptable when required device/interconnect layers map and LVS is CORRECT.'),
    (re.compile(r'Missing connections STAMPing layer'),
     'Calibre DRC connectivity-stamping warning from foundry rule derivation on optional device layers; review with nonzero DRC results, otherwise acceptable when the deck completes.'),
    (re.compile(r'Cell name parameter\s+for (NOT )?INSIDE CELL operation not located'),
     'Calibre foundry-rule warning from an empty optional cell-name parameter; review the corresponding guideline rule results before signoff.'),
	    (re.compile(r'PROJECTING constraint only supported with PARALLEL ONLY'),
	     'Calibre rule-kernel normalization warning from legacy foundry SVRF syntax; acceptable when the deck compiles and summary results are reviewed.'),
	    (re.compile(r'Expression\(s\) with at least one evaluation failure|MIN\(\.\.\.\) undefined -- no geometries evaluated'),
	     'Calibre foundry-rule property evaluation warning caused by empty optional geometries; acceptable only after checking the affected rulechecks and summary counts.'),
	    (re.compile(r'Invalid PATHCHK request .* no (POWER|GROUND) nets present'),
	     'Calibre ERC PATHCHK side warning caused by block-level port/label handling; acceptable for this block LVS when the compare is CORRECT and PG labeling is reviewed separately.'),
	    (re.compile(r'TEXT PRINT MAXIMUM limit .* exceeded'),
	     'Calibre report truncation warning; acceptable when the LVS/DRC summary is reviewed and the result database/report remains complete enough for signoff triage.'),
	(re.compile(r'STDMACROS environment variable was not found|User.s Guide .* missing'),
	 'TestMAX installation/help-file warning; does not affect ATPG execution when the netlist reads, DRC runs, and patterns are written.'),
	(re.compile(r'Rule N5 \(redefined module\)'),
	 'TestMAX library-model duplicate definition warning; acceptable when the cell library reads with zero errors and the intended top model is built.'),
	(re.compile(r'faultable pins lost due to tied gate optimizations|Rule B9 \(undriven module internal net\)|Rule B10 \(unconnected module internal net\)'),
	 'TestMAX optimization/connectivity warning for tied or unused logic; acceptable for signoff bookkeeping when ATPG completes, but review coverage for production test quality.'),
	(re.compile(r'Rule N20 \(underspecified UDP\)'),
	 'TestMAX UDP modeling warning; ATPG can complete, but generated patterns should be validated in simulation before production use.'),
	(re.compile(r'Rule S19 \(nonscan cell disturb\)|Rule C2 \(unstable nonscan DFF when clocks off\)|Rule C3 \(no latch transparency when clocks off\)'),
	 'TestMAX scan-DRC warning from nonscan sequential behavior during scan operation; patterns are generated, but coverage/scan simulation must be reviewed before production release.'),
]

WARNING_RE = re.compile(r'^(---\s*)?(Warning|WARNING)[: ]')
ERROR_RE = re.compile(
    r'^\s*(?:[-*]+\s*)?(Error|ERROR|Fatal|FATAL|Severe|SEVERE)(?=[:\s\]\)\*-]|$)|'
    r'^\s*\[(?:[A-Za-z0-9]+[-:])?(ERROR|Error|FATAL|Fatal|SEVERE|Severe)(?=[-:\]\s])'
)

def explain_warning(line):
    for pattern, explanation in WARNING_EXPLANATIONS:
        if pattern.search(line):
            return explanation
    return 'Unclassified warning; inspect manually before treating as explained.'

def message_code(line, fallback_prefix, fallback_index):
    match = re.search(r'\(([A-Za-z]+-[0-9]+)\)', line)
    if match:
        return match.group(1)
    match = re.search(r'\b([A-Z]+-[0-9]{3,4})\b', line)
    if match:
        return match.group(1)
    return '{}-{}'.format(fallback_prefix, fallback_index)

def Read_File(File_Path):
    warning_dict = OrderedDict()
    error_dict = OrderedDict()
    with open(File_Path,'r') as f_r:
        m = 0
        n = 0
        for lines in f_r.readlines():
            line = lines.strip()
            if line.startswith('//'):
                continue
            if WARNING_RE.search(line):
                key = message_code(line, 'NO_Type_Warning', m)
                if key.startswith('NO_Type_Warning'):
                    m += 1
                if key not in warning_dict.keys():
                    warning_dict[key] = [1, line, explain_warning(line)]
                else:
                    warning_dict[key][0] += 1
            if ERROR_RE.search(line):
                key = message_code(line, 'NO_Type_Error', n)
                if key.startswith('NO_Type_Error'):
                    n += 1
                if key not in error_dict.keys():
                    error_dict[key] = [1, line]
                else:
                    error_dict[key][0] += 1
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
    csv_writer.writerow(['Type','Num','Explanation','Description'])
    csv_writer.writerow(['Error','',''])    
    for key in error_dict.keys():
        #print('{}:{}'.format(key,error_dict[key]))
        Type = key
        Num  = error_dict[key][0]
        Des  = error_dict[key][1]
        csv_writer.writerow([Type,Num,'Must fix; flow fails on errors.',Des])
    csv_writer.writerow(['Warning','',''])
    for key in warning_dict.keys():
        #print('{}:{}'.format(key,warning_dict[key]))
        Type = key
        Num  = warning_dict[key][0]
        Des  = warning_dict[key][1]
        Exp  = warning_dict[key][2]
        csv_writer.writerow([Type,Num,Exp,Des])
    csvf.close()
    if error_dict:
        print('ERROR: {} contains {} error type(s); see {}'.format(
            file_path, len(error_dict), savedb_csv))
        sys.exit(1)
