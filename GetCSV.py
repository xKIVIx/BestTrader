import os
import argparse
import re

__currentDataRow = {}
__processedData = []
__scanTimestamp = 0


def ParseScanDumpDate(line: str):
    if "t_e date" in line:
        return ParseScanDump

    matches = re.search(r"overallMs=(?P<value>[0-9]+)", line)
    if matches:
        global __scanTimestamp
        __scanTimestamp = int(matches.groupdict()['value'])
        return ParseScanDumpDate

    return ParseScanDumpDate


def ParseLotInfo(line: str):
    global __currentDataRow
    global __processedData
    global __scanTimestamp
    matches = re.search(r"(?P<key>[\w]+)=(?P<value>[0-9]+)", line)
    if matches:
        __currentDataRow[matches.groupdict()['key']] = int(
            matches.groupdict()['value'])
        return ParseLotInfo

    matches = re.search(r"(?P<key>[\w]+)=(L|l)(?P<value>\"[\w ]*\")", line)
    if matches:
        __currentDataRow[matches.groupdict()['key']] = matches.groupdict()[
            'value']
        return ParseLotInfo

    matches = re.search(r"t_e [0-9]+", line)
    if matches:
        __currentDataRow["scanTime"] = __scanTimestamp
        __processedData.append(__currentDataRow)
        __currentDataRow = {}
        return ParseScanDumpResult
    return ParseLotInfo


def ParseScanDumpResult(line: str):
    matches = re.search(r"t_b [0-9]+", line)
    if matches:
        return ParseLotInfo

    if "t_e result" in line:
        return ParseScanDump


def ParseScanDump(line: str):
    if "t_b date" in line:
        return ParseScanDumpDate

    if "t_b result" in line:
        return ParseScanDumpResult

    if "t_e ScriptUserMods_scan_dump" in line:
        return ParseIdleState

    return ParseScanDump


def ParseIdleState(line: str):
    if "t_b ScriptUserMods_scan_dump" in line:
        return ParseScanDump

    return ParseIdleState


def Parse(inputPath, outputPath):
    with open(inputPath, "r", encoding="utf-8-sig") as inputFile:
        parser = ParseIdleState
        for line in inputFile:
            parser = parser(line)


if __name__ == "__main__":
    inputPath = f"{os.path.dirname(os.path.abspath(__file__))}/../../Configs/BestTrader/user.cfg"
    outputPath = "result.csv"
    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('--input', nargs='?',
                        help='Allod settings with dump', default=inputPath)
    parser.add_argument('--output', nargs='?',
                        help='Output csv', default="result.csv")

    args = parser.parse_args()
    Parse(args.input, args.output)

    with open(outputPath, "w", encoding="utf-8") as outputFile:
        outputFile.write(",".join(__processedData[0].keys()) + "\n")
        for row in __processedData:
            outputFile.write(",".join([str(row[k]) for k in row]) + "\n")
