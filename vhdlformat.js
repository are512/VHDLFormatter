"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const fs = require("fs");
const process = require("process");
const commander = require("commander");
const VHDLFormatter_1 = require("./VHDLFormatter");
;
function beautify(input, settings) {
    try {
        const data = VHDLFormatter_1.beautify(input, settings);
        return {
            data,
            err: null,
        };
    }
    catch (err) {
        return {
            data: null,
            err,
        };
    }
}
function main(options) {
    return new Promise((resolve, reject) => {
        if (!fs.existsSync(options.inputFile)) {
            console.error(`-- [ERROR]: could not read filename "${options.inputFile}"`);
            reject(new Error("Could not find file"));
            return;
        }
        fs.readFile(options.inputFile, (err, data) => {
            if (err != null || ((typeof data) === "undefined")) {
                console.error(`-- [ERROR]: could not read filename "${options.inputFile}"`);
                reject(err);
            }
            const input_vhdl = data.toString('utf8');
            const newlinesdict = {};
            newlinesdict[";"] = options.newLineSemi;
            newlinesdict["then"] = options.newLineThen;
            newlinesdict["else"] = options.newLineElse;
            const newLinesSetting = VHDLFormatter_1.ConstructNewLineSettings(newlinesdict);
            const alignSettings = new VHDLFormatter_1.signAlignSettings(options.signAlignRegional, options.signAlignAll, options.signAlignMode, options.signAlignKeywords);
            const settings = new VHDLFormatter_1.BeautifierSettings(options.removeComments, options.removeReports, options.checkAlias, alignSettings, options.keyWordCase, options.typeCase, options.indentation, newLinesSetting, options.endOfLine);
            const result = beautify(input_vhdl, settings);
            if (result.err !== null) {
                console.error(`-- [ERROR]: could not beautify "${options.inputFile}"`);
                reject(err);
            }
            const output_vhdl = result.data;
            if (!options.quiet) {
                console.log(output_vhdl);
            }
            if (options.overwrite) {
                const data = new Uint8Array(Buffer.from(output_vhdl));
                fs.writeFile(options.inputFile, data, (err) => {
                    if (err) {
                        console.error(`-- [ERROR]: could not save "${options.inputFile}"`);
                        reject(err);
                    }
                    else {
                        console.log(`-- [INFO]: saved file "${options.inputFile}"`);
                        resolve();
                    }
                });
            }
            else {
                console.error(`-- [INFO]: read file "${options.inputFile}"`);
                resolve();
            }
        });
    });
}
(() => {
    let myCommander = commander
        .description('vhdlformat beautifies your vhdl sources. It can indentat lines and change cases of the string literals.')
        .option('--key-word-case <casestr>', 'upper or lower-case the VHDL keywords', 'uppercase')
        .option('--type-case <casestr>', 'upper or lower-case the VHDL types', 'uppercase')
        .option('--indentation <blankstr>', 'Unit of the indentation.', '    ')
        .option('--end-of-line <eol>', 'Can set the line endings depending your platform.', '\r\n')
        .option('--inputFiles <path>', 'The input files that should be beautified')
        .option('--sign-align-regional <bool>', '', 'false')
        .option('--sign-align-all <bool>', 'Align all signs in the file', 'true')
        .option('--sign-align-mode <casestr>', 'blank, local or global', '')
        .option('--sign-align-keywords', 'keywords to be aligned', '')
        .option('--new-line-semi <casestr>', 'NewLine or NoNewLine or None', 'NewLine')
        .option('--new-line-then <casestr>', 'NewLine or NoNewLine or None', 'NewLine')
        .option('--new-line-else <casestr>', 'NewLine or NoNewLine or None', 'NewLine')
        .option('--overwrite', '', '')
        .option('--debug', '', '')
        .option('--quiet', '', '')
        .option('--remove-comments', '', '')
        .option('--remove-reports', '', '')
        .option('--check-alias', '', '')
        .version('0.1.0', '-v, --version');
    let args = myCommander.parse(process.argv);
    args.inputFiles = args.args;
    if (args.inputFiles.length < 1) {
        console.error("-- [ERROR]: must specify at least one input filename");
        myCommander.help();
        return;
    }
    args.inputFiles.forEach((input) => {
        args.inputFile = input;
        main(args).catch((err) => {
            if (args.verbose) {
                console.error(err);
            }
        });
    });
})();
//# sourceMappingURL=vhdlformat.js.map
