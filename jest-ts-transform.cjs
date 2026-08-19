'use strict';

const ts = require('typescript');

exports.process = (sourceText, sourcePath) => {
  const result = ts.transpileModule(sourceText, {
    compilerOptions: {
      module: ts.ModuleKind.CommonJS,
      target: ts.ScriptTarget.ES2020,
      esModuleInterop: true,
      jsx: ts.JsxEmit.React,
      sourceMap: true,
      inlineSourceMap: true,
      isolatedModules: true,
    },
    fileName: sourcePath,
  });
  return { code: result.outputText };
};
