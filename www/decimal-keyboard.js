var argscheck = require('cordova/argscheck'),
  utils = require('cordova/utils'),
  exec = require('cordova/exec');

var DecimalKeyboard = function () {

};

DecimalKeyboard.getActiveElementType = function () {
  if (document.activeElement.getAttribute('done-button')) {
    return 'done-button';
  } else if (document.activeElement.getAttribute('decimal-char')) {
    return 'decimal-char';
  }
  return document.activeElement.type;
};

DecimalKeyboard.isDecimal = function () {
  return document.activeElement.hasAttribute('decimal-char');
};

DecimalKeyboard.getDecimalChar = function (activeElement) {
  if (activeElement == undefined || activeElement == null || activeElement == 'undefined') {
    activeElement = document.activeElement;
  }
  return activeElement.getAttribute('decimal-char') || null;
};

DecimalKeyboard.addDecimal = function () {
  var activeElement = document.activeElement;
  var allowMultipleDecimals = true;
  if (activeElement.attributes["allow-multiple-decimals"] == undefined ||
    activeElement.attributes["allow-multiple-decimals"] == 'undefined' ||
    activeElement.attributes["allow-multiple-decimals"].value == 'false') {
    allowMultipleDecimals = false;
  }
  var value = activeElement.value;
  var valueToSet = '';
  var decimalChar = DecimalKeyboard.getDecimalChar(activeElement);
  var caretPosStart = activeElement.selectionStart;
  var caretPosEnd = activeElement.selectionEnd;
  var first = '';
  var last = '';

  first = value.substring(0, caretPosStart);
  last = value.substring(caretPosEnd);

  if (allowMultipleDecimals) {
    valueToSet = first + decimalChar + last;
  } else {
    if (value.indexOf(decimalChar) > -1)
      return;
    else {
      if (caretPosStart == 0) {
        first = '0';
      }
      if (activeElement.inputmask && !last) {
        last = ' ';
      }
      valueToSet = first + decimalChar + last;
    }
  }

  activeElement.value = valueToSet;

  if(activeElement.attributes["fire-decimal-event"] == undefined &&
      activeElement.attributes["fire-decimal-event"] == 'undefined' &&
      activeElement.attributes["fire-decimal-event"].value == 'true'){
          var keyEvent = new KeyboardEvent('keyup', { key: decimalChar, code: 256, charCode: 256, keyCode: 256, which: 256 });
          activeElement.dispatchEvent(keyEvent);
  }
};


DecimalKeyboard.onDoneClick = function () {
  var keyEvent = new KeyboardEvent('keyup', { key: 'Enter', code: 'Enter', charCode: 0, keyCode: 13, which: 13 });
  document.activeElement.dispatchEvent(keyEvent);
  document.activeElement.blur();
};


DecimalKeyboard.getDoneTitle = function () {
  return document.activeElement.getAttribute('done-button');
};

module.exports = DecimalKeyboard;
