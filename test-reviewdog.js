// Test file for reviewdog ESLint validation
// This file intentionally has some ESLint issues to test reviewdog

var unusedVariable = "this should trigger ESLint";

function testFunction() {
    console.log("test");
    // Missing semicolon should trigger ESLint
    return true
}

// Unused function should trigger ESLint
function unusedFunction() {
    return false;
}

// Trailing comma should trigger ESLint
const testObject = {
    prop1: "value1",
    prop2: "value2",
};

module.exports = {
    testFunction
};
