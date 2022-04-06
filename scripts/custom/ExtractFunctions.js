function ExtractFunctions() {
    var funcRegex = /([a-zA-Z0-9\*]+) ([_a-zA-Z0-9\*]+)\((.*)\)/
    var functionElements = document.querySelectorAll('.section > dl > dd > div > dl > dt');

    var results = [];
    for (var functionElement of functionElements) {
        var functionText = functionElement.innerText.replace(/ \*/gi, '* ');
        var regexResult = funcRegex.exec(functionText);
        regexResult.shift();
        var uncleanedReturnType = regexResult.shift();
        var cleanedReturnType = CleanType(uncleanedReturnType);
        var functionName = regexResult.shift();
        var unRegexedParameters = regexResult.shift();
        var uncleanedParameters = (unRegexedParameters || '').split(',');
        var cleanedParameters = [];
        for (var uncleanParameter of uncleanedParameters) {
            if (!uncleanParameter) break;
            var splitParam = uncleanParameter.replace(/ =.*/, '').split(' ').map(p => p.replace(',',''));
            var paramName = splitParam.pop();
            var paramType = CleanType(splitParam.join(' '));
            cleanedParameters.push(`${paramName}: ${paramType}`);
        }
        var returnType = cleanedReturnType ? `: ${cleanedReturnType}` : '';
        var constructedField = `---@field ${functionName} fun(${cleanedParameters.join(', ')})${returnType}`;
        results.push(constructedField);
    }
    return results;
}

function CleanType(type) {
    var lookupMap = {
        short: 'number',
        int: 'number',
        double: 'number',
        float: 'number',
        char: 'number',
        'char*': 'string',
        bool: 'boolean',
    }
    var splitType = type.split(' ');
    return lookupMap[splitType[splitType.length - 1].trim()];
}

var res = ExtractFunctions();
res.reduce((acc, cur) => {
    acc += `${cur}\n`
    return acc;
}, "");
