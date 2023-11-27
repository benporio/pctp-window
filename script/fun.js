class DataTableManipulator {
    static changeRowColor(jTableRow, color) {
        jTableRow.find('td').each(function () {
            $(this).css('background-color', color)
        })
    }

    static diableRowInputs(jTableRow, checkIfWillDisabled = (jElement) => true) {
        jTableRow.find('input, select').each(function () {
            if (checkIfWillDisabled($(this))) $(this).attr('disabled', true);
        })
    }

    static enableRowInputs(jTableRow) {
        jTableRow.find('input, select').each(function () {
            $(this).attr('disabled', false);
        })
    }
}

class Timer {
    #startTime;
    constructor() {
        this.#startTime = null;
    }
    isStarted() {
        return this.#startTime !== null;
    }
    start() {
        this.#startTime = new Date();
    }
    stop(doIncludeSeconds = false) {
        const endTime = new Date();
        const timeDiffInMin = ((endTime - this.#startTime) / 1000) / 60;
        const timeDiffInSec = ((endTime - this.#startTime) / 1000);
        this.#startTime = null;
        return Math.round(timeDiffInMin) === 0 ? `${Math.round(timeDiffInSec)} sec`
            : `${Math.round(timeDiffInMin)} min ${doIncludeSeconds ? `${Math.round(timeDiffInSec)%60} sec` : ''}`
    }
}

// Select/Unselect all
const selectUnselectAll = (jMainCheckRow, tabName) => {
    p.isMainCheckboxChecked[tabName] = jMainCheckRow.is(':checked')
    $(`#tabtbl${tabName}`).DataTable().$('tr').each(function () {
        const jCheckRow = $(this).find('input[type=checkbox]');
        jCheckRow.prop('checked', jMainCheckRow.is(':checked'))
        selectTableRow(jCheckRow)
        selectRow(jCheckRow)
    });
    if (!p.isMainCheckboxChecked) {
        p.resetGroupChangeProps(tabName);
    }
}

// Highlighting row when clicking in the current row
const selectTableRow = (jCheckRow, forceSelectRow = false) => {
    let jTableRow = p.getRow(jCheckRow);
    let tabName = p.getActiveTabName();
    if (jCheckRow.is(':checked')) {
        if (!jTableRow.hasClass('selected') || forceSelectRow) {
            jTableRow.addClass('selected')
            DataTableManipulator.changeRowColor(jTableRow, jTableRow.hasClass('locked-data-row') ? p.viewOptions.selected_locked_row_background_color : p.viewOptions.selection_background_color)
        }
        if (p.isMainCheckboxChecked[tabName]) p.excludedRowsFromSelection[tabName] = p.excludedRowsFromSelection[tabName].filter(e => e !== jTableRow.data('pctpCode'))
    } else {
        if (p.isMainCheckboxChecked[tabName]) p.excludedRowsFromSelection[tabName].push(jTableRow.data('pctpCode'))
        p.unselectTableRow(jTableRow);
    }
}

class IgnorableError extends Error {
    constructor(message, callback) {
        super(message);
        this.name = "IgnorableError";
        this.callback = callback;
    }
}

// Field event listeners and validators
const fieldEvent = (jElement, eventType, targetTabName = '', globalEvent = '') => {
    try {
        let proceedFieldOnchange = true;
        let activeTabName = targetTabName ? targetTabName : p.getActiveTabName();
        let row = p.getRow(jElement);
        if (p.columnValidations[activeTabName] !== undefined) {
            let fieldName = jElement.data('pctpModel');
            let activeTabValidations = p.columnValidations[activeTabName];
            if (activeTabValidations[fieldName] !== undefined) {
                if (activeTabValidations[fieldName].events[eventType] !== undefined) {
                    let jElementValue = p.getAnonymousElementValue(jElement);
                    let eventOptions = activeTabValidations[fieldName].events[eventType].filter(o => p.isValidData(jElementValue) && o.values.includes('DEFAULT'));
                    eventOptions = eventOptions.concat(activeTabValidations[fieldName].events[eventType].filter(o => {
                        return o.for.includes(globalEvent)
                            && (o.values.includes(jElementValue) || (!o.values.length && (new RegExp(o.regex)).test(jElementValue)));
                    }));
                    if (!eventOptions.length) {
                        if (!targetTabName) fieldOnchange(jElement);
                        return;
                    }
                    for (const eventOption of eventOptions) {
                        let observee = eventOption.observee;
                        let success = true;
                        if (observee !== undefined && Object.keys(observee.invalidValues).length) {
                            for (const field of observee.fields) {
                                let e = row.find(`*[data-pctp-model="${field.replace(/^_/, '')}"]`);
                                let value = '';
                                if (!e.length) {
                                    p.log('cannot find observee', field, jElement)
                                    p.refreshDataValue(jElement)
                                    p.log(`Cannot find element of field: ${field}`);
                                    success = false;
                                } else {
                                    value = p.getAnonymousElementValue(e);
                                    let invalidValues = [];
                                    if (observee.invalidValues[field] !== undefined) {
                                        if (observee.invalidValues[field].passedValues !== undefined
                                            && observee.invalidValues[field].passedValues.includes(value)) continue;
                                        if (observee.invalidValues[field].values === undefined) {
                                            if (observee.invalidValues.default !== undefined) {
                                                invalidValues = observee.invalidValues.default;
                                            } else {
                                                invalidValues = p.viewOptions.default_input_invalid_values;
                                            }
                                        } else {
                                            invalidValues = observee.invalidValues[field].values;
                                        }
                                    } else if (observee.invalidValues.default !== undefined) {
                                        invalidValues = observee.invalidValues.default;
                                    } else {
                                        invalidValues = observee.invalidValues;
                                    }
                                    let exempted = false;
                                    if (invalidValues.includes(String(value).trim())) {
                                        if (!!observee.exemptions) {
                                            const { allOtherFieldMatch } = observee.exemptions;
                                            if (!!allOtherFieldMatch && allOtherFieldMatch.every(match => {
                                                const fieldValue = String(p.getElementModelValue(activeTabName, row, match.field)).trim()
                                                if (match.value.includes('@')) {
                                                    return p.constants[match.value.replace('@', '')].includes(fieldValue)
                                                } else {
                                                    return fieldValue == String(match.value).trim()
                                                }
                                            })) exempted = true;
                                        }
                                        if (exempted && !!observee?.exemptions?.success) {
                                            let successEvent = observee.exemptions.success;
                                            let arg = {
                                                row: row,
                                                activeTabName: activeTabName,
                                                jElement: jElement,
                                                ...successEvent.arg,
                                            }
                                            if (!!observee?.exemptions?.revert) {
                                                jElement.on('excempt:revert', (event) => {
                                                    let revertEvent = observee.exemptions.revert;
                                                    let arg = {
                                                        row: row,
                                                        activeTabName: activeTabName,
                                                        jElement: jElement,
                                                        ...revertEvent.arg,
                                                    }
                                                    p[revertEvent.callback](arg);
                                                    jElement.off('excempt:revert');
                                                })
                                                jElement.bind('change', (event) => {
                                                    if (event?.target?.value && !eventOptions.some(e => e.values.includes(event.target.value))) {
                                                        jElement.trigger('excempt:revert');
                                                    }
                                                })
                                            }
                                            p[successEvent.callback](arg);
                                        }
                                    }
                                    if (!exempted && invalidValues.includes(String(value).trim())) {
                                        p.log('invalid values detected', field, e[0].localName, jElement)
                                        p.log(`Field '${field}' should have a valid value`);
                                        if (observee.result !== undefined && observee.result.failed !== undefined 
                                            && (observee.result.failed.callback !== undefined
                                                || (!!observee.result.failed.for 
                                                    && ((!!globalEvent && !!observee.result.failed.for[globalEvent])
                                                        || (globalEvent==='' && !!observee.result.failed.for.default))))) {
                                            let failedEvent = observee.result.failed;
                                            let arg = {
                                                row: row,
                                                activeTabName: activeTabName,
                                                jElement: jElement,
                                                ...(failedEvent.arg !== undefined ? failedEvent.arg : {})
                                            }
                                            if (!!failedEvent.for) {
                                                if (!!globalEvent && !!failedEvent.for[globalEvent]) {
                                                    p[failedEvent.for[globalEvent]](arg)
                                                } else if (globalEvent==='' && !!failedEvent.for.default && !!failedEvent.for.default.callback) {
                                                    p[failedEvent.for.default.callback](arg)
                                                }
                                            } else if (p.isValidData(failedEvent.callback)) {
                                                p[failedEvent.callback](arg)
                                            }
                                        } else {
                                            p.refreshDataValue(jElement, row)
                                        }
                                        if (row.hasClass('selected')) {
                                            const jCheckRow = row.find('input[type=checkbox]');
                                            jCheckRow.prop('checked', false)
                                            selectTableRow(jCheckRow)
                                            selectRow(jCheckRow)
                                        }
                                        if (observee.invalidValues[field] !== undefined && observee.invalidValues[field].message !== undefined) {
                                            throw observee.invalidValues[field].message + `. (line ${row.find('span.rowNo').data('pctpRow')})`;
                                        }
                                        if (observee.result !== undefined && observee.result.failed !== undefined && observee.result.failed.message !== undefined) {
                                            const errMsg = observee.result.failed.message + `. (line ${row.find('span.rowNo').data('pctpRow')})`;
                                            // if (!!observee.result.failed.ignorable) {
                                            //     const { row, title, message, button1Label, button2Label, prop, info, callback, isOutsideCallback } = arg;
                                            //     p.promptMessage2Buttons2ReturnBools({
                                            //         row,
                                            //         title: 'Error (ignorable)',
                                            //         message: ''
                                            //     })
                                            //     p[failedEvent.callback](arg)
                                            //     throw new IgnorableError(errMsg, );
                                            // }
                                            throw errMsg;
                                        }
                                        throw `Field '${field}' should have a valid value. (line ${row.find('span.rowNo').data('pctpRow')})`;
                                    }
                                }
                            }
                        }
                        if (success && observee.result !== undefined && observee.result.evaluations !== undefined) {
                            let evaluations = observee.result.evaluations;
                            for (const evaluation of evaluations) {
                                let arg = {
                                    row: row,
                                    activeTabName: activeTabName,
                                    jElement: jElement,
                                    evaluation: evaluation,
                                    ...evaluation.arg,
                                }
                                let resultEval = true;
                                if (evaluation.type !== undefined && evaluation.type === 'async') {
                                    const callback = (evaluation, arg, returnedData) => {
                                        if (returnedData) {
                                            if (evaluation.failedMethod !== undefined) {
                                                p[evaluation.failedMethod](arg);
                                            } else {
                                                p.refreshDataValue(jElement, row)
                                            }
                                            if (evaluation.failedMessage !== undefined) {
                                                p.promptMessage1Button({ title: 'ERROR', message: evaluation.failedMessage, button1Label: 'OK', info: '' })
                                            } else {
                                                p.promptMessage1Button({ title: 'ERROR', message: 'Something went wrong', button1Label: 'OK', info: '' })
                                            }
                                        }
                                    }
                                    if (!(globalEvent === 'initialize' && evaluation.callback.includes('prompt'))) resultEval = p[evaluation.callback](arg, callback);
                                } else {
                                    if (!(globalEvent === 'initialize' && evaluation.callback.includes('prompt'))) resultEval = p[evaluation.callback](arg);
                                    if (resultEval) {
                                        if (evaluation.failedMethod !== undefined) {
                                            p[evaluation.failedMethod](arg);
                                        } else {
                                            p.refreshDataValue(jElement, row)
                                        }
                                        if (evaluation.failedMessage !== undefined) throw evaluation.failedMessage
                                        throw `Something went wrong. (line ${row.find('span.rowNo').data('pctpRow')})`
                                    }
                                }
                            }
                        }
                        if (success && observee.result !== undefined && observee.result.success !== undefined) {
                            let successEvent = observee.result.success;
                            if (successEvent.proceedFieldOnchange !== undefined) proceedFieldOnchange = successEvent.proceedFieldOnchange;
                            let arg = {
                                row: row,
                                activeTabName: activeTabName,
                                jElement: jElement,
                                ...successEvent.arg,
                                relatedUpdateMonitor: function (jRow, targetField, formula, value) {
                                    let rowCode = jRow.data('pctpCode');
                                    if (p.relatedUpdates.length) {
                                        if (p.relatedUpdates.some(r => r.rowCode === rowCode)) {
                                            for (const r of p.relatedUpdates) {
                                                if (r.rowCode === rowCode) {
                                                    if (r.relatedProps.some(r => r.targetField === targetField)) {
                                                        r.relatedProps.forEach((item, index, arr) => {
                                                            if (arr[index].targetField === targetField) arr[index].value = value;
                                                        });
                                                    } else {
                                                        r.relatedProps.push({
                                                            targetField: targetField,
                                                            value: value,
                                                            subject: formula
                                                        })
                                                    }
                                                }
                                            }
                                        } else {
                                            p.relatedUpdates.push({
                                                rowCode: rowCode,
                                                relatedProps: [{
                                                    targetField: targetField,
                                                    value: value,
                                                    subject: formula
                                                }]
                                            })
                                        }
                                    } else {
                                        p.relatedUpdates.push({
                                            rowCode: rowCode,
                                            relatedProps: [{
                                                targetField: targetField,
                                                value: value,
                                                subject: formula
                                            }]
                                        })
                                    }
                                    p.log('relatedUpdates', p.relatedUpdates)
                                }
                            }
                            if (!(globalEvent === 'initialize' && successEvent.callback.includes('prompt'))) {
                                p[successEvent.callback](arg);
                                if (!!arg?.field) {
                                    const fieldName = arg.field.replace(/^_/, '')
                                    if (!!arg?.otherTab) {
                                        !!p.modelPostTriggers[arg.otherTab]?.[fieldName] && p.modelPostTriggers[arg.otherTab][fieldName]()
                                    } else if (!!arg?.activeTabName) {
                                        !!p.modelPostTriggers[arg.activeTabName]?.[fieldName] && p.modelPostTriggers[arg.activeTabName][fieldName]()
                                    }
                                }
                            }
                            if (!targetTabName) selectTableRow(row.find('input[type=checkbox]'), true);
                        }
                    }
                }
            }
        }
        if (!targetTabName && proceedFieldOnchange) {
            fieldOnchange(jElement);
        } else if (!targetTabName && !proceedFieldOnchange) {
            p.addModifiedRow(p.parseDataRow(row, activeTabName), activeTabName);
        }

        p.log('modified-rows', p.modifiedRows);
    } catch (error) {
        p.log(error)
        if (!globalEvent) promptMessage1Button('ERROR', error, 'OK');
    }
}

// File upload listener
const fileUploadRemoveListener = (input) => {
    try {
        if ($(input).html() === 'REMOVE') {
            p.removeUploadedAttachment(p.getActiveTabName(), p.currentRowTabCode);
        } else {
            if (!p.isValidData($(input).val()) || !p.isValidData($(input)[0].files[0].name)) return
            p.addUploadedAttachment(p.getActiveTabName(), p.currentRowTabCode, $(input)[0].files[0]);
        }
        let attachment = p.uploadedAttachment[p.getActiveTabName()][p.currentRowTabCode].attachment;
        if (p.viewOptions.auto_hide_attachment_modal_upon_upload_remove) {
            $('#uploadmodal').modal('hide');
        } else {
            renderUploadModal(attachment)
        }
        p.isValidData(attachment) ? p.currentAttachmentLink.html('1 attachment').prop('title', attachment)
            : p.currentAttachmentLink.html('No attachment').prop('title', '');
        fieldOnchange(p.currentAttachmentLink)
    } catch (error) {
        p.log(error)
        promptMessage1Button('ERROR', error, 'OK');
    }
    $(input).val('');
    p.log(p.uploadedAttachment)
}

// Attachment link control
const clickAttachmentLink = (linkTag, event) => {
    if ($(linkTag).parent().parent().hasClass('locked-data-row')) {
        event.preventDefault();
        return;
    }
    p.currentAttachmentLink = $(linkTag);
    p.currentRowTabCode = p.getRow(p.currentAttachmentLink).data('pctpCode');
    if (p.uploadedAttachment.hasOwnProperty(p.getActiveTabName())) {
        let attachmentObj = p.uploadedAttachment[p.getActiveTabName()][p.currentRowTabCode];
        if (p.isValidData(attachmentObj) && attachmentObj.hasOwnProperty('attachment')) renderUploadModal(attachmentObj.attachment, true)
    }
    event.preventDefault();
}

const renderUploadModal = (attachment, reopenModal = false) => {
    let uploadModal = $('#uploadmodal');
    if (reopenModal) uploadModal.modal('hide');
    if (p.getActiveTabName() === 'pod') {
        $('#uploadmodalbtnupload').removeClass('d-none');
    } else {
        if (!$('#uploadmodalbtnupload').hasClass('d-none')) $('#uploadmodalbtnupload').addClass('d-none');
    }
    let html = '';
    html += '<div class="container-fluid">'
    if (!p.isValidData(attachment)) {
        html += '<div class="row d-flex">'
        html += '<div class="col-12 text-center">'
        html += '<span>No Attachment</span>'
        html += '</div>'
        html += '</div>'
        $('#uploadmodalbtnupload').html('UPLOAD');
    } else {
        html += '<div class="row d-flex">'
        html += `<div class="col-6 text-center">`
        html += '<span>' + attachment + '</span>'
        html += '</div>'
        html += '<div class="col-6 text-center">'
        html += `<button style="margin: 2px;" onclick="location.href='../res/download.php?code=${p.currentRowTabCode}&file=${encodeURIComponent(attachment)}&option=download'">DOWNLOAD</button>`
        if (attachment.includes('.pdf')) {
            html += `<button style="margin: 2px;" onclick="window.open('../res/download.php?code=${p.currentRowTabCode}&file=${encodeURIComponent(attachment)}&option=view','_blank')">VIEW</button>`
        }
        if (p.getActiveTabName() === 'pod') {
            html += '<button style="margin: 2px;" onclick="fileUploadRemoveListener(this)">REMOVE</button>'
        }
        html += '</div>'
        html += '</div>'
        $('#uploadmodalbtnupload').html('REPLACE');
    }
    html += '</div>'
    uploadModal.find('div.modal-body').html('');
    uploadModal.find('div.modal-body').html(html);
    if (reopenModal) uploadModal.modal('show');
}

//
const loadingMethodWrapper = async (info, ...methods) => {
    if (p.isValidData(info)) {
        setScreenLoading(true, false, info);
    } else {
        setScreenLoading(true);
    }
    await timeout(10)
    for (const method of methods) {
        method()
    }
    setScreenLoading(false);
}

// Onchange event and checking for modification
const fieldOnchange = (jElement) => {
    p.fieldOnchange(jElement);
}

// Selecting Row via checkbox, only modified rows will checked
const selectRow = (checkbox, isDirectClick = true) => {
    let row = p.getRow(checkbox);
    if (!p.isValidData(row.data('pctpCode')) && isDirectClick) {
        promptMessage1Button(
            'ERROR', 
            `'${p.getBookingId(p.getActiveTabName(), row)}' might be missing from the main table of ${p.getActiveTabName().toUpperCase()}. Cannot modify this row`, 
            'OK'
        );
        return;
    }
    let activeTabName = p.getActiveTabName();
    if (checkbox.is(':checked')) {
        let data = p.parseDataRow(row, activeTabName);
        p.addModifiedRow(data, activeTabName);
        if (!p.selectedModifiedRows.some(z => z === row.data('pctpCode'))) p.selectedModifiedRows.push(row.data('pctpCode'));
    } else {
        p.selectedModifiedRows = p.selectedModifiedRows.filter(z => z !== row.data('pctpCode'));
    }
    if (isDirectClick) {
        p.log('modified-rows', p.modifiedRows);
        p.log('selected-modified-rows', p.selectedModifiedRows);
        p.renderCountTabUpdate(activeTabName);
    }
    if (['billing', 'tp'].includes(activeTabName)) {
        if (checkbox.is(':checked')) {
            p.selectedSapDataRows.push(p.parseDataRow(row, activeTabName, true));
        } else {
            p.selectedSapDataRows = p.selectedSapDataRows.filter(z => z.rowCode !== row.data('pctpCode'));
        }
        p.log('selected-rows', p.selectedSapDataRows);
    }
}

// Render header fields with passed header data from back end
const renderHeader = (header) => {
    $('input[data-pctp-header]').each(function () {
        $(this).val(header[$(this).data('pctpHeader')]);
    })
    $('input.dateInputVal.header').each(function () {
        console.log($(this));
        $(this).val(!p.isValidData(header[$(this).siblings().data('pctpHeader')]) ? '' : p.SAPDateFormater(header[$(this).siblings().data('pctpHeader')]));
    })
    $('select[data-pctp-header]').each(function () {
        for (const option of header.dropDownOptions[$(this).data('pctpOptions')]) {
            $(this).append($('<option>', {
                value: option.Code,
                text: option.Name
            }));
        }
    })
}

// Initialize module by ajax calling controller.initialize()
const initialize = (afterInitEvent) => {
    result = $.ajax({
        type: 'GET',
        url: '../res/action.php',
        data: { action: 'initialize' },
        async: false
    }).responseText;
    try {
        p.log('init-data-pctp-received', JSON.parse(result))
        result = JSON.parse(result)
        afterInitEvent(result, () => setScreenLoading(false));
        return result;
    } catch (error) {
        p.log(result)
    }
}

const findTimer = new Timer();

// Ajax call to execute controller's public methods
const callAction = async (actionName, arg) => {
    p.log(p.modifiedRows)
    if (!p.validateAction(actionName)) {
        setScreenLoading(false, true)
        return false;
    }
    let data = {};
    data['activeTab'] = p.getActiveTabName();
    let count = 0, fullCount = 0, results = [], sapObjs = [], isErrorEncounter = false, bookingIdsForPodUpdate = [];
    p.preActionCallBacks.run(actionName)
    switch (actionName) {
        case 'find':
            $('span.findTimeElapsed').html('');
            findTimer.start();
            setScreenLoading(true);
            data['header'] = p.parseHeader();
            p.log('data-pctp-passed', data)
            p.selectedModifiedRows = p.selectedModifiedRows.filter(s => !s.includes(p.getActiveTabName()))
            p.resetGroupChangeProps(data.activeTab);
            p.renderCountTabUpdate();
            const resultData = await p.actionAjax(actionName, data);
            p.log('resultData', resultData)
            p.fetchTableRowsCount[data.activeTab] = resultData.fetchTableRowsCount
            if (!p.fetchTableRowsCount[data.activeTab]) setScreenLoading(false, true)
            return resultData
        case 'update':
            setScreenLoading(true);
            const broadCastIdsForUpdate = []
            if (!p.selectedModifiedRows.length) {
                p.showInfo('No modified rows detected', 3000)
                setScreenLoading(false, false)
                return;
            }
            p.log('modifiedRows', p.modifiedRows)
            let dataForUpdate = p.getTabModifiedRows(p.getActiveTabName());
            let tabRows = dataForUpdate.tabRows;
            if (!tabRows.length) {
                p.showInfo('No modified rows detected', 3000)
                setScreenLoading(false, false)
                return;
            }
            let childRows = dataForUpdate.childRows;
            let childTab = dataForUpdate.childTab;
            p.log('tabRows', dataForUpdate)
            // processing of attachments or uploads
            p.showInfo('Updating rows...')
            if (p.isMainCheckboxChecked[data.activeTab] && Object.keys(p.groupChangeProps[data.activeTab]).length) {
                data['groupFieldProps'] = p.groupChangeProps[data.activeTab];
                data['excludedRowsFromSelection'] = p.excludedRowsFromSelection[data.activeTab];
                await p.actionAjax('groupFieldUpdate', data)
            }
            if (tabRows.length) {
                for (const row of tabRows) {
                    row['userInfo'] = p.userInfo;
                    broadCastIdsForUpdate.push(row.BookingId)
                    if (p.isValidData(row.upload) && typeof row.upload === 'object' && row.props.Attachment === row.upload.name) {
                        let returnData = await uploadAjax(row);
                        p.log('file-upload-result', returnData)
                        if (returnData.result === 'success') {
                            row.uploaded = 'yes';
                            p.log('uploaded-row:', row)
                            p.uploadedAttachment[p.getActiveTabName()][`${p.getActiveTabName()}.${row.Code}`] = {
                                attachment: row.upload.name,
                                removed: 'no',
                                upload: null,
                                uploaded: 'no'
                            }
                        } else {
                            row.uploaded = 'no';
                        }
                    } else {
                        row.uploaded = 'ignore';
                    }
                }
                let validatedRows = JSON.parse(JSON.stringify(tabRows));
                validatedRows.forEach((v, i, arr) => {
                    if (p.relatedUpdates.some(r => r.rowCode === arr[i].rowCode)) {
                        arr[i]['relatedProps'] = p.relatedUpdates.filter(r => r.rowCode === arr[i].rowCode)[0].relatedProps
                    }
                })
                p.log('validatedRows', validatedRows)
                data['rows'] = validatedRows;
                p.log('data-pctp-passed', data)
                await p.actionAjax(actionName, data, childRows.length ? null : () => setScreenLoading(false))
                if (!!p.realtimeDataRowController) {
                    p.realtimeDataRowController.broadcastUpdate({
                        group: data.activeTab,
                        ids: broadCastIdsForUpdate
                    })
                }
            }
            if (!childRows.length) return;
            if (childRows.length) {
                data['activeTab'] = childTab;
                for (const row of childRows) {
                    if (p.isValidData(row.upload) && typeof row.upload === 'object' && row.props.Attachment === row.upload.name) {
                        let returnData = await uploadAjax(row);
                        p.log('file-upload-result', returnData)
                        if (returnData.result === 'success') {
                            row.uploaded = 'yes';
                        } else {
                            row.uploaded = 'no';
                        }
                    }
                }
                let validatedRows = JSON.parse(JSON.stringify(childRows));
                p.log('validatedRows', validatedRows)
                data['rows'] = validatedRows;
                p.log('data-pctp-passed', data)
                return await p.actionAjax(actionName, data, () => setScreenLoading(false))
            }
            setScreenLoading(false, true)
            break;
        case 'createSalesOrder':
            setScreenLoading(true, false, '', true);
            if (!p.selectedSapDataRows.length) {
                p.showInfo('No selected rows detected', 3000)
                setScreenLoading(false)
                return;
            }
            sapObjs = p.createSapObjs('SALES_ORDER', 'SAPClient')
            console.log(sapObjs);
            if (!sapObjs.length) {
                setScreenLoading(false)
                return;
            }
            fullCount = sapObjs.length
            prepProgressBar();
            try {
                for (const sapObj of sapObjs) {
                    count++;
                    progressBar(count, fullCount, 'Creating Sales Order');
                    data['sapObj'] = sapObj;
                    p.log('data-pctp-passed', data)
                    let result = await p.actionAjax(actionName, data);
                    p.log(result)
                    if (!result.valid) {
                        remProgressBar();
                        setScreenLoading(false)
                        p.showError('Sales Order Creation Failed');
                        promptMessage1Button('ERROR', result.message, 'OK');
                        isErrorEncounter = true;
                        break;
                    }
                    results.push(result)
                }
                remProgressBar();
                if (!isErrorEncounter) p.showSuccess('Created Sales Order Successfully');
                for (const result of results) {
                    for (const rData of result.rData) {
                        p.refreshUpdatedRowsFromTab(rData.rDataRows, rData.rowData !== undefined ? rData.rowData : null);
                    }
                }
                setScreenLoading(false)
            } catch (error) {
                console.log(error)
                setScreenLoading(false)
                remProgressBar();
                p.hidePortalMessage(3000);
                isErrorEncounter = true;
            }
            break;
        case 'createArInvoice':
            setScreenLoading(true, false, '', true);
            if (!p.selectedSapDataRows.length) {
                p.showInfo('No selected rows detected', 3000)
                setScreenLoading(false)
                return;
            }
            sapObjs = p.createSapObjs('AR_INVOICE', 'SAPClient')
            console.log(sapObjs);
            if (!sapObjs.length) {
                setScreenLoading(false)
                return;
            }
            fullCount = sapObjs.length
            prepProgressBar();
            try {
                for (const sapObj of sapObjs) {
                    count++;
                    progressBar(count, fullCount, 'Creating AR Invoice');
                    data['sapObj'] = sapObj;
                    p.log('data-pctp-passed', data)
                    let result = await p.actionAjax(actionName, data);
                    p.log(result)
                    if (!result.valid) {
                        remProgressBar();
                        setScreenLoading(false)
                        p.showError('AR Invoice Creation Failed');
                        promptMessage1Button('ERROR', result.message, 'OK');
                        isErrorEncounter = true;
                        break;
                    }
                    sapObj.lines.map(line => bookingIdsForPodUpdate.push(line.ItemCode))
                    results.push(result)
                }
                await updatePodRowsByBookingNumber(isErrorEncounter, bookingIdsForPodUpdate);
                remProgressBar();
                if (!isErrorEncounter) p.showSuccess('Created AR Invoice Successfully');
                setScreenLoading(false)
            } catch (error) {
                console.log(error)
                setScreenLoading(false)
                remProgressBar();
                p.hidePortalMessage(3000);
                isErrorEncounter = true;
            }
            break;
        case 'createApInvoice':
            setScreenLoading(true, false, '', true);
            if (!p.selectedSapDataRows.length) {
                p.showInfo('No selected rows detected', 3000)
                setScreenLoading(false)
                return;
            }
            sapObjs = p.createSapObjs('AP_INVOICE', 'TruckerSAP')
            console.log(sapObjs);
            if (!sapObjs.length) {
                setScreenLoading(false)
                return;
            }
            fullCount = sapObjs.length
            prepProgressBar();
            try {
                for (const sapObj of sapObjs) {
                    count++;
                    progressBar(count, fullCount, 'Creating AP Invoice');
                    data['sapObj'] = sapObj;
                    p.log('data-pctp-passed', data)
                    let result = await p.actionAjax(actionName, data);
                    p.log(result)
                    if (!result.valid) {
                        remProgressBar();
                        setScreenLoading(false)
                        p.showError('AP Invoice Creation Failed');
                        promptMessage1Button('ERROR', result.message, 'OK');
                        isErrorEncounter = true;
                        break;
                    }
                    sapObj.lines.map(line => bookingIdsForPodUpdate.push(line.ItemCode))
                    results.push(result)
                }
                await updatePodRowsByBookingNumber(isErrorEncounter, bookingIdsForPodUpdate);
                remProgressBar();
                if (!isErrorEncounter) p.showSuccess('Created AP Invoice Successfully');
                setScreenLoading(false)
            } catch (error) {
                console.log(error)
                setScreenLoading(false)
                remProgressBar();
                p.hidePortalMessage(3000);
                isErrorEncounter = true;
            }
            break;
        case 'downloadAttachment':
            setScreenLoading(true);
            if (p.isValidData(arg)) {
                let dataArg = {};
                dataArg['code'] = arg[0];
                dataArg['file'] = arg[1];
                data['arg'] = dataArg;
                p.log('data-pctp-passed', data)
                return await p.actionAjax(actionName, data, () => setScreenLoading(false, true))
            }
            break;
        default:
            setScreenLoading(false);
    }
}

const updatePodRowsByBookingNumber = async (isErrorEncounter, bookingIdsForPodUpdate) => {
    if (!isErrorEncounter && bookingIdsForPodUpdate.length) {
        [{
            tabName: 'pod',
            fieldName: 'BookingNumber'
        },
        {
            tabName: 'pricing',
            fieldName: 'BookingId'
        }].map(async obj => {
            if (p.hasDataTable(obj.tabName)) {
                let rowCodes = [];
                for (const bookingNumber of bookingIdsForPodUpdate) {
                    if (bookingNumber) {
                        let jRow = p.findTableRowByFieldValue(obj.tabName, obj.fieldName, bookingNumber.trim())
                        if (jRow !== null) rowCodes.push(jRow.data('pctpCode'));
                    }
                }
                if (rowCodes.length) await p.refreshDataRow({ tabName: obj.tabName, rowCodes: rowCodes })
            }
        })
    }
}

// File Upload Ajax
const uploadAjax = async (row) => {
    try {
        let file_data = row.upload;
        let form_data = new FormData();
        form_data.append('file', file_data);
        form_data.append('code', row.Code);
        p.log(form_data);
        return await $.ajax({
            url: '../res/upload.php',
            dataType: 'json',
            cache: false,
            contentType: false,
            processData: false,
            data: form_data,
            type: 'post',
            success: function (res) {
                return res;
            }
        });
    } catch (error) {
        p.showError(error.message)
    }

}

// Show or unshow loading animation
const setScreenLoading = (isLoading, hidePortalMessage = false, infoWhenLoading = '', showOnlyLoading = false) => {
    if (showOnlyLoading) {
        $('#loadingAnimation').removeClass('d-none')
        return;
    }
    isLoading ? $('#loadingAnimation').removeClass('d-none') : $('#loadingAnimation').addClass('d-none');
    if (isLoading) p.showInfo(p.isValidData(infoWhenLoading) ? infoWhenLoading : 'Please wait...')
    if (hidePortalMessage) p.hidePortalMessage();
}

// Make timeout in millisecond
const timeout = (ms) => new Promise(resolve => setTimeout(resolve, ms));

const ENUM = {
    DataRowStatus: {
        UNLOCKED: 'UNLOCKED',
        LOCKED: 'LOCKED',
    },
    SocketMessageType: {
        MESSAGE: 'MESSAGE',
        BROADCAST: 'BROADCAST',
    },
    SocketEventType: {
        CONNECTION_ESTABLISHED: 'CONNECTION_ESTABLISHED',
        REGISTRATION: 'REGISTRATION',
        CLEAN_UP: 'CLEAN_UP',
        RELEASE: 'RELEASE',
        UPDATE: 'UPDATE',
        CLOSE: 'CLOSE',
        ASK_TO_UNLOCK: 'ASK_TO_UNLOCK',
    },
    SocketEventStatus: {
        REQUEST: 'REQUEST',
        FAILED: 'FAILED',
    }
}

// Classes
class DataRowRef {
    constructor(code, jRow, status = ENUM.DataRowStatus.UNLOCKED) {
        this.code = code;
        this.jRow = jRow;
        this.status = status;
    }
}

class DataRowRefManager {
    constructor() {
        this.pod = [];
        this.billing = [];
        this.tp = [];
        this.pricing = [];
    }
    clear(tabName) {
        this[tabName] = [];
    }
};

class SocketMessage {
    constructor(type, event) {
        this.sessionId = ''
        this.type = type
        this.event = event
        this.data = ''
    }
}

class WebSocketManager {
    #socket = null;
    #webSocketCaller = null;
    constructor(wsUrl, webSocketCaller) {
        this.#socket = new WebSocket(wsUrl);
        this.#webSocketCaller = webSocketCaller;
        this.#socket.onopen = (event) => {
            console.log('WebSocketServer has been connected')
        };
        this.#socket.onclose = ((socket, webSocketCaller) => (event) => {
            const closeEventHandlers = webSocketCaller.getEventHandler(ENUM.SocketEventType.CLOSE);
            if (!!closeEventHandlers)  {
                for (const eventHandler of closeEventHandlers) {
                    if (typeof eventHandler === 'function') {
                        eventHandler();
                    }
                }
            } else {
                console.log('WebSocketServer has been closed')
            }
            socket = null
        })(this.#socket, this.#webSocketCaller);
        this.#socket.onmessage = ((webSocketCaller) => (event) => {
            try {
                const eventData = JSON.parse(event.data);
                console.log(eventData);
                for (const eventHandler of webSocketCaller.getEventHandler(eventData.event)) {
                    if (typeof eventHandler === 'function') {
                        eventHandler(eventData);
                    }
                }
            } catch (error) {
                console.log(error);
                console.log(event);
            }
        })(this.#webSocketCaller);
    }
    send(socketMessage) {
        if (this.#socket !== null) {
            this.#socket.send(JSON.stringify(socketMessage));
        }
    }
    sendRegistration(sessionId, data) {
        const socketMessage = new SocketMessage(ENUM.SocketMessageType.MESSAGE, ENUM.SocketEventType.REGISTRATION);
        socketMessage.sessionId = sessionId
        socketMessage.data = data
        this.send(socketMessage)
    }
    sendCleanUp(sessionId, data) {
        const socketMessage = new SocketMessage(ENUM.SocketMessageType.MESSAGE, ENUM.SocketEventType.CLEAN_UP);
        socketMessage.sessionId = sessionId
        socketMessage.data = data
        this.send(socketMessage)
    }
    sendUpdate(sessionId, data) {
        const socketMessage = new SocketMessage(ENUM.SocketMessageType.BROADCAST, ENUM.SocketEventType.UPDATE);
        socketMessage.sessionId = sessionId
        socketMessage.data = data
        this.send(socketMessage)
    }
    askToUnlock(sessionId, data) {
        const socketMessage = new SocketMessage(ENUM.SocketMessageType.MESSAGE, ENUM.SocketEventType.ASK_TO_UNLOCK);
        socketMessage.sessionId = sessionId
        socketMessage.data = data
        this.send(socketMessage)
    }
}

class AbsWebSocketCaller {
    getEventHandlers() {
        return {};
    }
    getEventHandler(eventType) {
        return null
    }
}

class RealtimeDataRowController extends AbsWebSocketCaller {
    #webSocketManager;
    #eventHandlers = {};
    #clientId;
    #dataRowRefManager;
    #viewOptions;
    #userInfo;
    #unlockRequests;
    constructor(url, userInfo, viewOptions) {
        super();
        this.#unlockRequests = [];
        this.#viewOptions = viewOptions;
        this.#userInfo = userInfo;
        this.#dataRowRefManager = new DataRowRefManager();
        // Initializing websocket event handlers
        this.#eventHandlers[ENUM.SocketEventType.CONNECTION_ESTABLISHED] = []
        this.#eventHandlers[ENUM.SocketEventType.CONNECTION_ESTABLISHED].push(((caller) => ({ data }) => {
            console.log('CONNECTION_ESTABLISHED', data)
            caller.#clientId = data.clientId;
            const dataRowRefManager = caller.#dataRowRefManager;
            for (const key in dataRowRefManager) {
                if (Object.hasOwnProperty.call(dataRowRefManager, key)) {
                    const tabDataRowRef = dataRowRefManager[key];
                    if (!!tabDataRowRef && tabDataRowRef.length) {
                        caller.#webSocketManager.sendRegistration(
                            caller.#userInfo.sessionId,
                            {
                                userId: caller.#userInfo.userId,
                                userName: caller.#userInfo.userName,
                                clientId: caller.#clientId,
                                prop: {
                                    group: key,
                                    ids: tabDataRowRef.map(item => item.code)
                                }
                            }
                        )
                    }
                }
            }
        })(this))

        this.#eventHandlers[ENUM.SocketEventType.CLOSE] = []
        this.#eventHandlers[ENUM.SocketEventType.CLOSE].push(((caller, url) => () => {
            console.log('CONNECTION_CLOSED')
            const dataRowRefManager = caller.#dataRowRefManager;
            for (const key in dataRowRefManager) {
                if (Object.hasOwnProperty.call(dataRowRefManager, key)) {
                    const tabDataRowRef = dataRowRefManager[key];
                    tabDataRowRef.filter(dataRow => dataRow.status === ENUM.DataRowStatus.LOCKED).forEach(dataRow => {
                        dataRow.status = ENUM.DataRowStatus.UNLOCKED
                        DataTableManipulator.changeRowColor(dataRow.jRow, caller.#viewOptions.td_background_color)
                        DataTableManipulator.enableRowInputs(dataRow.jRow)
                        dataRow.jRow.find('span.rowNo').html(dataRow.jRow.find('button.btnRowNo').html())
                        if (dataRow.jRow.hasClass('locked-data-row')) dataRow.jRow.removeClass('locked-data-row')
                    })
                }
            }

            (async function reconnectingWebSocket(url) {
                console.log('Trying to connect to WebSocketServer...')
                const testSocket = new WebSocket(url);
                testSocket.onopen = (event) => {
                    console.log('WebSocketServer is now available')
                    console.log('Trying to initialize the WebSocketManager...')
                    caller.#webSocketManager = new WebSocketManager(url, caller);
                };
                testSocket.onerror = async (event) => {
                    console.log('WebSocketServer has been closed')
                    await timeout(2000);
                    reconnectingWebSocket(url);
                };
            })(url);
        })(this, url))

        this.#eventHandlers[ENUM.SocketEventType.REGISTRATION] = []
        this.#eventHandlers[ENUM.SocketEventType.REGISTRATION].push(((caller) => ({ data : { prop: { ids, group, idInfo } } }) => {
            if (!ids) return;
            const tabDataRowRef = caller.#dataRowRefManager[group];
            if (tabDataRowRef) {
                // ids that are locked and not registered will be returned back
                ids.forEach(lockedBookingId => {
                    tabDataRowRef.filter(dataRow => dataRow.code === lockedBookingId).forEach(dataRow => {
                        DataTableManipulator.changeRowColor(dataRow.jRow, caller.#viewOptions.locked_row_background_color)
                        if (idInfo.some(info => info.id === lockedBookingId)) {
                            const userInfo = idInfo.filter(info => info.id === lockedBookingId)[0].userInfo
                            dataRow.jRow.attr('title', `Locked by ${userInfo.userName}`)
                        }
                        dataRow.jRow.addClass('locked-data-row')
                        dataRow.jRow.find('span.rowNo').html(
                            `<button type="button" class="btnRowNo" 
                                onclick="
                                    $('span.lockedId').html('${lockedBookingId}');
                                    $('#realTimeModal').modal('show');
                                    $('#btnAskToUnlock').attr('onclick', 'p.realtimeDataRowController.askToUnlock(\\'${group}\\', \\'${lockedBookingId}\\')')
                                "
                            >
                                ${dataRow.jRow.find('span.rowNo').html() }
                            </button>`
                        )
                        dataRow.status = ENUM.DataRowStatus.LOCKED
                        DataTableManipulator.diableRowInputs(
                            dataRow.jRow,
                            (jElement) => (!caller.#viewOptions.disable_checkbox_on_locked_data_row && jElement.attr('type') === 'checkbox') || jElement.attr('type') !== 'checkbox'
                        )
                    })
                })
            }
        })(this))

        this.#eventHandlers[ENUM.SocketEventType.RELEASE] = []
        this.#eventHandlers[ENUM.SocketEventType.RELEASE].push(((caller) => ({ data }) => {
            const tabDataRowRef = caller.#dataRowRefManager[data.prop.group];
            if (tabDataRowRef) {
                for (const dataRow of tabDataRowRef) {
                    if (dataRow.code === data.prop.id) {
                        dataRow.status = ENUM.DataRowStatus.UNLOCKED
                        DataTableManipulator.changeRowColor(dataRow.jRow, caller.#viewOptions.td_background_color)
                        DataTableManipulator.enableRowInputs(dataRow.jRow)
                        dataRow.jRow.find('span.rowNo').html(dataRow.jRow.find('button.btnRowNo').html())
                        if (dataRow.jRow.hasClass('locked-data-row')) dataRow.jRow.removeClass('locked-data-row')
                        break;
                    }
                }
            }
        })(this))

        this.#eventHandlers[ENUM.SocketEventType.UPDATE] = []
        this.#eventHandlers[ENUM.SocketEventType.UPDATE].push(((caller) => ({ data: { prop: { group, ids } } }) => {
            const tabDataRowRef = caller.#dataRowRefManager[group];
            const filteredTabDataRowRef = tabDataRowRef.filter(dataRow => ids.includes(dataRow.code))
            if (tabDataRowRef && filteredTabDataRowRef.length) {
                p.showInfo(`Receiving broadcast update for ${group.toUpperCase()} tab`, -1)
                filteredTabDataRowRef.forEach(async ({ jRow }, i, arr) => {
                    await p.refreshDataRow({
                        tabName: group,
                        rowCodes: [p.getRowCode(group, jRow, false)]
                    })
                    DataTableManipulator.diableRowInputs(
                        jRow,
                        (jElement) => (!caller.#viewOptions.disable_checkbox_on_locked_data_row && jElement.attr('type') === 'checkbox') || jElement.attr('type') !== 'checkbox'
                    )
                    if (i + 1 === arr.length) p.hidePortalMessage();
                })
            }
        })(this))

        this.#eventHandlers[ENUM.SocketEventType.ASK_TO_UNLOCK] = []
        this.#eventHandlers[ENUM.SocketEventType.ASK_TO_UNLOCK].push(((caller) => ({ data: { requestorInfo: { userName }, status, prop: { group, id }} }) => {
            switch (status) {
                case ENUM.SocketEventStatus.REQUEST:
                    if (caller.#unlockRequests.includes(`${group}${id}${userName}`.toUpperCase())) break;
                    caller.#unlockRequests.push(`${group}${id}${userName}`.toUpperCase());
                    const requestBody = $('#tblRequestToUnlock > tbody');
                    requestBody.append(`
                        <tr>
                            <td>
                                <span class="requestId">${id}</span>
                            </td>
                            <td>
                                <span class="requestGroup">${group.toUpperCase()}</span>
                            </td>
                            <td>
                                <span class="requestBy">${userName}</span>
                            </td>
                            <td>
                                <div class="actionsForRequest">
                                    <div>
                                        <button class="btnGrant" type="button">
                                            GRANT
                                        </button>
                                        <button class="btnIgnore" type="button">
                                            IGNORE
                                        </button>
                                    </div>
                                </div>
                            </td>
                        </tr>
                    `);
                    if (!$('#realTimeRequestModal').is(':visible')) $('#realTimeRequestModal').modal('show')
                    break;
                case ENUM.SocketEventStatus.FAILED:

                    break;
                default:
                    break;
            }
        })(this))

        this.#webSocketManager = new WebSocketManager(url, this);
    }

    get dataRowRefManager() {
        return this.#dataRowRefManager
    }

    getEventHandlers() {
        return this.#eventHandlers;
    }
    getEventHandler(eventType) {
        if (this.#eventHandlers[eventType]) {
            return this.#eventHandlers[eventType];
        }
        this.#eventHandlers[eventType] = []
        return this.#eventHandlers[eventType];
    }

    cleanUp(data) {
        this.#webSocketManager.sendCleanUp(this.#userInfo.sessionId, { clientId: this.#clientId, prop: data })
    }

    register(data) {
        this.#webSocketManager.sendRegistration(
            this.#userInfo.sessionId,
            {
                userId: this.#userInfo.userId,
                userName: this.#userInfo.userName,
                clientId: this.#clientId,
                prop: data
            }
        )
    }

    broadcastUpdate(data) {
        this.#webSocketManager.sendUpdate(this.#userInfo.sessionId, { clientId: this.#clientId, prop: data })
    }

    askToUnlock(group, id) {
        this.#webSocketManager.askToUnlock(
            this.#userInfo.sessionId,
            {
                userId: this.#userInfo.userId,
                userName: this.#userInfo.userName,
                clientId: this.#clientId,
                prop: {
                    group: group,
                    id: id
                }
            }
        )
    }
}

class PctpWindowView extends AbsWebSocketCaller {
    #selectedRows;
    #sapObjGrouping;
    #sapDocumentStructures;
    #uploadedAttachment;
    #columnValidations;
    #columnDefinitions;
    #fieldEnumValues;
    #foreignFields;
    #dropDownOptions;
    #constants;
    #actionValidations;
    #viewOptions;
    #config;
    #userInfo;
    #clientId = '';
    #realtimeDataRowController;
    #modelPostTriggers;
    constructor() {
        super();
        this.currentRowTabCode = '';
        this.currentAttachmentLink = {};
        this.modifiedRows = []; // Global array for storing modified rows for later update or any opertaion 
        this.selectedModifiedRows = []; // Global array for selected modified rows for later update or any opertaion 
        this.#selectedRows = []; // Global array for storing selected rows 
        this.selectedSapDataRows = []; // Global array for storing sapObj parsed from selected rows 
        this.#sapObjGrouping = {}; // Global array for storing sapObj parsed from selected rows 
        this.#uploadedAttachment = {};
        this.childUpdateRow = [];
        this.#actionValidations = {};
        this.#viewOptions = {};
        this.#config = {};
        this.#modelPostTriggers = {};
        this.relatedUpdates = [];
        this.user = {};
        this.rowIndexCodePairs = {
            summary: [],
            pod: [],
            billing: [],
            tp: [],
            pricing: [],
            treasury: [],
        };
        this.rowNumCodePairs = [];
        this.excludedRowsFromSelection = {
            pod: [],
            billing: [],
            tp: [],
        };;
        this.isMainCheckboxChecked = {
            pod: false,
            billing: false,
            tp: false,
        };
        this.groupChangeProps = {
            pod: {},
            billing: {},
            tp: {},
        };
        this.fetchTableRowsCount = {};
        this.transientChanges = {}
        this.doConstantsNeedRefresh = true;
        this.preActionCallBacks = {
            find: [],
            update: [],
            createSalesOrder: [],
            createArInvoice: [],
            createApInvoice: [],
            register(actionName, fn) {
                this[actionName].push(fn)
            },
            run(actionName) {
                if (this[actionName].length) this[actionName].forEach(fn => fn());
            }
        };
        const tabInitSettings = {
            hasExcelDownloadProcessing: false,
        }
        this.tabSettings = {
            summary: { ...tabInitSettings },
            pod: { ...tabInitSettings },
            billing: { ...tabInitSettings },
            tp: { ...tabInitSettings },
            pricing: { ...tabInitSettings },
            treasury: { ...tabInitSettings },
        }
        this.fetchedIdsToProcess = [];
    }

    get clientId() {
        this.#clientId
    }

    set clientId(clientId) {
        this.#clientId = clientId
    }

    get userInfo() {
        return this.#userInfo;
    }
    get columnDefinitions() {
        return this.#columnDefinitions;
    }
    get modelPostTriggers() {
        return this.#modelPostTriggers;
    }
    get uploadedAttachment() {
        return this.#uploadedAttachment;
    }
    get selectedRows() {
        return this.#selectedRows;
    }
    get columnValidations() {
        return this.#columnValidations;
    }
    get constants() {
        return this.#constants
    }
    get viewOptions() {
        return this.#viewOptions
    }
    get sapObjGrouping() {
        return this.#sapObjGrouping
    }
    get sapDocumentStructures() {
        return this.#sapDocumentStructures
    }
    set sapDocumentStructures(sapDocumentStructures) {
        this.#sapDocumentStructures = sapDocumentStructures
    }
    get realtimeDataRowController() {
        return this.#realtimeDataRowController
    }
    initialize(data) {
        this.#sapDocumentStructures = data.sapDocumentStructures;
        this.#uploadedAttachment = data.uploadedAttachment;
        this.#columnValidations = data.columnValidations;
        this.#columnDefinitions = data.columnDefinitions;
        this.#fieldEnumValues = data.fieldEnumValues;
        this.#foreignFields = data.foreignFields;
        this.#dropDownOptions = data.dropDownOptions;
        this.emptySapObjGrouping();
        this.#actionValidations = data.actionValidations;
        this.#viewOptions = data.viewOptions;
        this.#config = data.config;
        this.#userInfo = data.userInfo;
        this.user = data.user;
        if (this.doConstantsNeedRefresh) {
            this.log('constants have been refreshed')
            this.#constants = data.constants;
            this.doConstantsNeedRefresh = false
            setTimeout(() => { p.doConstantsNeedRefresh = true; p.log('doConstantsNeedRefresh has now been set to true') }, this.#viewOptions.constants_refresh_waiting_time)
        }
        this.#realtimeDataRowController = this.getConfig('enable_data_row_realtime', false) ? new RealtimeDataRowController(`ws://${window.location.hostname}:8000/`, data.userInfo, data.viewOptions) : null;
        const fetchedIdsToProcessEvent = new EventSource(`http://${window.location.hostname}:8000/sse/id-to-refresh`);
        fetchedIdsToProcessEvent.onerror = (event) => {
            if ($('#nodenotify').hasClass('blinking')) $('#nodenotify').removeClass('blinking')
            $('#nodenotify').attr('title', `Event handler has stopped`);
            $('.node-notify-info').html(`Event handler has stopped`);
        }
        fetchedIdsToProcessEvent.onmessage = ((p) => async (event) => {
            try {
                const data = JSON.parse(event.data);
                if (!!!data.ignorable || !data.ignorable) {
                    console.log(data);
                    if (!!data.fetchedIdsToProcess) {
                        if (this.getConfig('enable_fetch_ids_to_process', false)) p.fetchedIdsToProcess = data.fetchedIdsToProcess;
                        if (data.fetchedIdsToProcess.length) {
                            const eventArr = []
                            const eventsRegex = new RegExp(/AP\d+|AR\d+|SO\d+|OP\d+|MISSING|DUP|BN/);
                            try {
                                for (const eventId of data.fetchedIdsToProcess) {
                                    if (eventArr.some(e => eventId.serial.includes(e.event))) {
                                        const event = eventId.serial.match(eventsRegex)[0];
                                        for (const eventItem of eventArr) {
                                            if (event == eventItem.event) {
                                                eventItem.ids.push(eventId.id)
                                                break;
                                            }
                                        }
                                    } else {
                                        try {
                                            if (eventId.serial.match(eventsRegex).length) {
                                                eventArr.push({
                                                    event: eventId.serial.match(eventsRegex)[0],
                                                    ids: [eventId.id]
                                                })
                                            }
                                        } catch (error) {
                                            console.log(error, eventId)
                                        }
                                    }
                                }
                                if (!!eventArr.length) {
                                    const eventInfo = eventArr.map(e => `<strong>${e.event}</strong> - <span title="${e.ids.join(', ')}">${e.ids.length} BN(s)</span>`).join(', ')
                                    $('#nodenotify').attr('title', `Ongoing background activity`);
                                    $('.node-notify-info').html(`Refreshing BN(s) involve in: ${eventInfo}`);
                                } else {
                                    $('#nodenotify').attr('title', `Ongoing background activity`);
                                    $('.node-notify-info').html(`Ongoing background activity`);
                                }
                            } catch (error) {
                                p.log(error)
                                $('#nodenotify').attr('title', `Ongoing background activity`);
                                $('.node-notify-info').html(`Background activity failed to give info`);
                            }
                            if (!$('#nodenotify').hasClass('blinking')) $('#nodenotify').addClass('blinking')
                        } else {
                            if ($('#nodenotify').hasClass('blinking')) $('#nodenotify').removeClass('blinking')
                            $('#nodenotify').attr('title', `No background activity`);
                            $('.node-notify-info').html(`No background activity`);
                        }
                    }
                }
            } catch (error) {
                console.log(error);
                console.log(event.data);
            }
        })(this);
        setScreenLoading(false)
    }
    getConfig(configName, defaultValue) {
        return this.#config[configName] ?? defaultValue;
    }
    parseHeader() {
        let data = {};
        $('input[data-pctp-header]').each(function () {
            data[$(this).data('pctpHeader')] = $(this).is(':checkbox') ? $(this).is(':checked') : ($(this).val() === null ? null : String($(this).val()).trim());
        })
        $('select[data-pctp-header]').each(function () {
            data[$(this).data('pctpHeader')] = $(this).val() === null ? null : String($(this).val()).trim();
        })
        return data;
    }
    async actionAjax(actionName, data, callback = null) {
        return await $.post('../res/action.php', { action: actionName, data: data }).then((d) => {
            try {
                p.log('data-pctp-received', JSON.parse(d));
                let data = JSON.parse(d)
                if (data.type !== undefined && data.type === 'error') throw data.message
                if (data.result == 'success') {
                    if (p.isValidData(data.message) && p.isValidData(callback)) p.showSuccess(data.message)
                    if (p.isValidData(data.callback)) {
                        p[data.callback](data.arg, callback === null ? null : () => callback());
                        if (callback !== null) {
                            callback();
                        } else {
                            return data.resultData;
                        }
                    } else {
                        if (callback !== null) {
                            callback();
                        } else {
                            return data.resultData;
                        }
                    }
                } else {
                    if (p.isValidData(data.message) && p.isValidData(callback)) p.showError(data.message)
                    if (callback !== null) {
                        callback();
                    } else {
                        return data.resultData;
                    }
                }
            } catch (error) {
                p.showError(error)
                p.log(error)
                p.log(d)
                if (callback !== null) {
                    callback();
                }
            }
        });
    }
    addUploadedAttachment(tabName, code, file) {
        if (this.#uploadedAttachment[tabName][code] !== undefined) {
            if (this.#uploadedAttachment[tabName][code].attachment === file.name) throw 'Selected file is already uploaded';
        }
        if (this.#uploadedAttachment[tabName][code] === undefined) {
            this.#uploadedAttachment[tabName][code] = { attachment: file.name, upload: file };
        }
        this.#uploadedAttachment[tabName][code].attachment = file.name
        this.#uploadedAttachment[tabName][code].upload = file
    }
    removeUploadedAttachment(tabName, code) {
        if (this.#uploadedAttachment[tabName][code] === undefined) {
            this.#uploadedAttachment[tabName][code] = { attachment: '', upload: {} };
        } else {
            this.#uploadedAttachment[tabName][code].attachment = ''
            this.#uploadedAttachment[tabName][code].upload = {};
        }
    }
    emptySapObjGrouping(sapDocumentStructureType = '') {
        if (this.isValidData(sapDocumentStructureType)) {
            this.#sapObjGrouping[sapDocumentStructureType] = { sapDataObjs: [] };
        } else {
            let sapDocumentStructures = this.#sapDocumentStructures;
            for (const sapDocumentStructureType in sapDocumentStructures) {
                if (Object.hasOwnProperty.call(sapDocumentStructures, sapDocumentStructureType)) {
                    this.#sapObjGrouping[sapDocumentStructureType] = { sapDataObjs: [] };
                }
            }
        }
    }
    createSapObjs(sapDocumentStructureType, groupingField) {
        this.emptySapObjGrouping()
        let sapObjGroupings = {};
        for (const selectedSapDataRow of this.selectedSapDataRows.filter(s => s.tab === this.getActiveTabName())) {
            if (!Object.keys(sapObjGroupings).length) {
                sapObjGroupings[selectedSapDataRow.props[groupingField]] = { sapDataRows: [selectedSapDataRow] };
            } else if (sapObjGroupings[selectedSapDataRow.props[groupingField]] !== undefined) {
                sapObjGroupings[selectedSapDataRow.props[groupingField]].sapDataRows.push(selectedSapDataRow)
            } else {
                sapObjGroupings[selectedSapDataRow.props[groupingField]] = { sapDataRows: [selectedSapDataRow] };
            }
        }
        let sapDataObjs = []
        const structureOption = this.#sapDocumentStructures[sapDocumentStructureType];
        for (const groupName in sapObjGroupings) {
            if (Object.hasOwnProperty.call(sapObjGroupings, groupName)) {
                const groupProp = sapObjGroupings[groupName];
                if (groupProp !== undefined
                    && groupProp.sapDataRows !== undefined
                    && groupProp.sapDataRows.length) {
                    let headers = this.parseFieldObj(groupProp.sapDataRows[0], structureOption.headers, structureOption);
                    if (headers.failedValidations.length) {
                        this.showError(`Validation message(s): '${headers.failedValidations.join("', '")}' - line ${headers.rowData.rowNum}`)
                        return [];
                    } else if (headers.missingDataFields.length) {
                        this.showError(`Missing valid values on field(s) '${headers.missingDataFields.join("', '")}' - line ${headers.rowData.rowNum}`)
                        return [];
                    }
                    let lines = []
                    for (const sapDataRow of groupProp.sapDataRows) {
                        let obj = this.parseFieldObj(sapDataRow, structureOption.lines, structureOption, 'line')
                        if (obj.failedValidations.length) {
                            this.showError(`Validation message(s): '${obj.failedValidations.join("', '")}' - line ${obj.rowData.rowNum}`)
                            return [];
                        } else if (obj.missingDataFields.length) {
                            this.showError(`Missing valid values on field(s) '${obj.missingDataFields.join("', '")}' - line ${obj.rowData.rowNum}`)
                            return [];
                        }
                        lines.push(obj)
                    }
                    let sapDataObj = {
                        timeSerial: Date.now(),
                        headers: headers,
                        lines: lines,
                        info: {
                            posted: false,
                            docNum: 0
                        }
                    }
                    sapDataObjs.push(sapDataObj)
                }
            }
        }
        this.#sapObjGrouping[sapDocumentStructureType].sapDataObjs = sapDataObjs;
        return sapDataObjs;
    }
    parseFieldObj(selectedSapData, option, structureOption, type = '') {
        const { defaults, columnTypes, fieldValidations } = structureOption
        let obj = {};
        let missingDataFields = [];
        let failedValidations = [];
        obj['rowData'] = {
            rowCode: selectedSapData.rowCode,
            Code: selectedSapData.Code,
            tab: selectedSapData.tab,
            rowNum: selectedSapData.rowNum,
            podNum: selectedSapData.props.PODNum,
        }
        for (const dataField in fieldValidations) {
            if (Object.hasOwnProperty.call(fieldValidations, dataField)) {
                const fieldValidation = fieldValidations[dataField];
                if (!fieldValidation.enabled) continue
                if (fieldValidation.regex !== undefined) {
                    let formattedValue = this.formatValue(fieldValidation.columnType, selectedSapData.props[dataField], false)
                    if (!(new RegExp(fieldValidation.regex)).test(formattedValue)) {
                        if (fieldValidation.failedMessage !== undefined) {
                            failedValidations.push(fieldValidation.failedMessage)
                        }
                        if (fieldValidation.overrideRegex && !(new RegExp(fieldValidation.overrideRegex)).test(formattedValue)) {
                            if (fieldValidation.overrideFailedMessage !== undefined) {
                                failedValidations.push(fieldValidation.overrideFailedMessage)
                            }
                        } else {
                            if (fieldValidation.overrideLine !== undefined && type === 'line') {
                                option = fieldValidation.overrideLine;
                                obj['overrideLine'] = fieldValidation.overrideLine;
                            }
                        }
                    }
                }
                if (fieldValidation.invalidValues !== undefined) {
                    let formattedValue = this.formatValue(fieldValidation.columnType, selectedSapData.props[dataField], false)
                    if (fieldValidation.invalidValues.includes(formattedValue)) failedValidations.push(fieldValidation.failedMessage)
                }

            }
        }
        for (const sapField in option) {
            if (Object.hasOwnProperty.call(option, sapField)) {
                const dataField = option[sapField];
                if (Array.isArray(dataField)) {
                    let accValue = 0;
                    for (const eachDataField of dataField) {
                        let formattedValue = this.formatValue(columnTypes[sapField], selectedSapData.props[eachDataField], false)
                        if (this.isValidData(formattedValue)) {
                            accValue += Number(formattedValue);
                        } else {
                            if (!p.viewOptions.multiple_rates_selection.invalid_value_return_0) missingDataFields.push(eachDataField)
                        }
                    }
                    obj[sapField] = accValue;
                } else {
                    let formattedValue = this.formatValue(columnTypes[sapField], selectedSapData.props[dataField], false)
                    if (this.isValidData(formattedValue)) {
                        obj[sapField] = formattedValue;
                    } else if ((defaults[sapField] !== undefined && defaults[sapField] === '') || this.isValidData(defaults[sapField])) {
                        obj[sapField] = defaults[sapField];
                    } else {
                        missingDataFields.push(dataField)
                    }
                }
            }
        }
        obj['missingDataFields'] = missingDataFields;
        obj['failedValidations'] = failedValidations;
        return obj;
    }
    addModifiedRow(data, tab) {
        try {
            if (Object.keys(data).length > 4) {
                if (this.modifiedRows.length && this.modifiedRows.some(z => z.tab === tab)) {
                    for (const tabRows of this.modifiedRows) {
                        if (tabRows.tab === tab) {
                            if (tabRows.rows.length) {
                                let storedData = tabRows.rows.filter(z => z.Code === data.Code)
                                if (storedData.length) {
                                    tabRows.rows = tabRows.rows.filter(z => z.Code !== data.Code)
                                    tabRows.rows.push(data);
                                } else {
                                    tabRows.rows.push(data);
                                }
                            } else {
                                tabRows.rows.push(data);
                            }
                            break;
                        }
                    }
                } else {
                    this.modifiedRows.push({ tab: tab, rows: [data] });
                }
                return true
            } else {
                const tabRows = this.modifiedRows.filter(z => z.tab === tab)
                if (tabRows.length) {
                    this.modifiedRows.forEach(z => {
                        if (z.tab === tab) z.rows = z.rows.filter(x => x.Code !== data.Code);
                    })
                }
                return false
            }
        } catch (error) {
            console.log(error)
            promptMessage1Button('ERROR', 'Cannot add modified row.', 'OK', error)
            return false
        }
    }
    getTabModifiedRows(tabName) {
        try {
            let selectedCodes = this.selectedModifiedRows.map(z => z.replace(new RegExp(`^${p.getActiveTabName()}`), ''))
            let filteredModifiedRows = this.modifiedRows.filter(z => z.tab === tabName)
            let tabRows = filteredModifiedRows.length ? filteredModifiedRows[0].rows.filter(z => z.props && selectedCodes.includes(z.Code)) : []
            let childCodes = (this.childUpdateRow.map(c => this.selectedModifiedRows.includes(c.parent) ? c.child : null)).filter(c => this.isValidData(c));
            let childTab = childCodes.length ? childCodes[0].replace(/\d+/, '') : '';
            let filteredModifiedChildRows = this.modifiedRows.filter(z => z.tab === childTab)
            let selectedChildCodes = childCodes.map(z => z.replace(new RegExp(`^${childTab}`), ''))
            let childRows = filteredModifiedChildRows.length ? filteredModifiedChildRows[0].rows.filter(z => selectedChildCodes.includes(z.Code)) : []
            return {
                tabRows: tabRows,
                childRows: childRows,
                childTab: childCodes.length ? childCodes[0].replace(/\d+/, '') : ''
            }
        } catch (error) {
            throw error
        }
    }
    renderCountTabUpdate(tabName) {
        let tabModifiedRows = this.selectedModifiedRows.filter(z => z.includes(tabName));
        if (tabModifiedRows.length) {
            $('#btnaddupdate').removeAttr('disabled');
            $('#btnaddupdate').html(`UPDATE${this.isMainCheckboxChecked[tabName] ? '' : ` (${tabModifiedRows.length})`}`);
        } else {
            $('#btnaddupdate').attr('disabled', true);
            $('#btnaddupdate').html(`UPDATE`);
        }
    }
    renderPostingButtons(tabName) {
        $('#btncreatesalesorder').attr('disabled', true);
        $('#btncreatearinvoice').attr('disabled', true);
        $('#btncreateapinvoice').attr('disabled', true);
        switch (tabName) {
            case 'billing':
                $('#btncreatesalesorder').removeAttr('disabled');
                $('#btncreatearinvoice').removeAttr('disabled');
                break;
            case 'tp':
                $('#btncreateapinvoice').removeAttr('disabled');
                break;
            default:
                break;
        }
    }
    isValidData(data) {
        if (data === undefined || data === null || data === '') return false;
        return true;
    }
    getRowCode(tab, row, doReplaceTabFromRowCode = true) {
        if (!doReplaceTabFromRowCode) return row.data('pctpCode')
        return row.data('pctpCode').replace(new RegExp(`^${tab}`), '');
    }
    async reloadTab(arg, callback = null) {
        if (!$('#resultDiv').find(`div[data-pctp-model="${arg.tab}"]`).length) return;
        setScreenLoading(true, false, '', true)
        $(`#${arg.tab}tabpaneloading`).removeClass('d-none')
        if (!$(`#${arg.tab}excel`).hasClass('d-none')
            && !$(`#${arg.tab}excel`).find('.fa-file-excel').css('animation').includes('color-change')) $(`#${arg.tab}excel`).addClass('d-none');
        $(`#${arg.tab}loading`).removeClass('d-none')
        if (!$(`#${arg.tab}tabpanecontent`).hasClass('d-none')) $(`#${arg.tab}tabpanecontent`).addClass('d-none')
        const cb = (t, callback) => {
            this.initializeDataTable($(`#tabtbl${t}`), t);
            if (callback !== null) {
                callback();
            }
        }
        if (arg.uploadedAttachment !== undefined) {
            this.#uploadedAttachment[arg.tab] = arg.uploadedAttachment;
            p.log('uploadedAttachment:', this.#uploadedAttachment)
        }
        $(`#${arg.tab}tabpanecontent`).load(`../templates/components/ptcp-table-tab.php?tab=${arg.tab}`, () => cb(arg.tab, callback));
        if (arg.tab === 'pod') this.modifiedRows = [];
        this.selectedSapDataRows = this.selectedSapDataRows.filter(d => d.tab !== arg.tab)
    }
    #runObserversEvents(jParent, targetTabName, globalEvent = '', jRow = null) {
        if (jRow === null) {
            jParent.DataTable().$('*[data-pctp-observer]').each(function () {
                if (p.columnValidations[targetTabName][$(this).data('pctpModel')] !== undefined) fieldEvent($(this), 'onchange', targetTabName, globalEvent);
            })
        } else {
            jRow.find('*[data-pctp-observer]').each(function () {
                if (p.columnValidations[targetTabName][$(this).data('pctpModel')] !== undefined) fieldEvent($(this), 'onchange', targetTabName, globalEvent);
            })
        }
    }
    async initializeDataTable(tbl, tabName) {
        if (!tbl.find('tr td.nodataplaceholder').length) {
            tbl.DataTable({
                serverSide: true,
                deferRender: true,
                lengthMenu: [10, 25, 50, 100, 200, 400],
                ajax: {
                    url: '../res/api.php',
                    type: 'POST',
                    data: {
                        action: 'fetchDataRows',
                        data: {
                            tab: tabName,
                            fetchedIdsToProcess: !!this.fetchedIdsToProcess ? this.fetchedIdsToProcess.map(e => e.id) : null
                        }
                    }
                },
                createdRow: function (row, data, index) {
                    let tdCode = $(row).find('td span[data-pctp-code]');
                    let code = tdCode.data('pctpCode')
                    tdCode.removeAttr('data-pctp-code')
                    $(row).attr('data-pctp-code', code)
                    let checkbox = $(row).find('input[type=checkbox]')
                    if (p.transientChanges[code]) {
                        const jRow = $(row);
                        const transientProps = p.transientChanges[code];
                        for (const field in transientProps) {
                            if (Object.hasOwnProperty.call(transientProps, field)) {
                                const value = transientProps[field];
                                let targetElement = jRow.find(`*[data-pctp-model="${field.replace(/^_/, '')}"]`)
                                if (targetElement.length) {
                                    targetElement = p.setAnonymousElementValue(tabName, targetElement, value);
                                    p.fieldOnchange(targetElement, tabName);
                                }
                            }
                        }
                        delete p.transientChanges[code];
                    }
                    if (p.isMainCheckboxChecked[tabName] && !p.excludedRowsFromSelection[tabName].some(e => e === code)) {
                        checkbox.prop('checked', true)
                        selectTableRow(checkbox, true)
                        const modifiedTabRows = p.modifiedRows.filter(m => m.tab === tabName);
                        if (!modifiedTabRows.length || !modifiedTabRows[0].rows.length || !modifiedTabRows[0].rows.some(m => m.rowCode === code)) {
                            selectRow(checkbox)
                            for (const field in p.groupChangeProps[tabName]) {
                                if (Object.hasOwnProperty.call(p.groupChangeProps[tabName], field)) {
                                    const value = p.groupChangeProps[tabName][field];
                                    const targetElement = p.getElementModel($(row), field);
                                    p.setAnonymousElementValue(tabName, targetElement, value)
                                    p.fieldOnchange(targetElement);
                                }
                            }
                        }
                    } else if (p.selectedSapDataRows.some(z => z.rowCode === code)) {
                        checkbox.prop('checked', true)
                        selectTableRow(checkbox, true)
                    }
                    if (p.selectedModifiedRows.some(z => z === code)) {
                        if (!p.isMainCheckboxChecked[tabName]) {
                            checkbox.prop('checked', true)
                            selectTableRow(checkbox, true)
                        }
                        const modifiedTabRows = p.modifiedRows.filter(m => m.tab === tabName);
                        if (modifiedTabRows.length) {
                            for (const modifiedRow of modifiedTabRows[0].rows) {
                                if (modifiedRow.rowCode === code) {
                                    for (const field in modifiedRow.props) {
                                        if (Object.hasOwnProperty.call(modifiedRow.props, field)) {
                                            const value = modifiedRow.props[field];
                                            const targetElement = p.getElementModel($(row), field);
                                            p.setAnonymousElementValue(tabName, targetElement, value)
                                            p.fieldOnchange(targetElement);
                                        }
                                    }
                                }
                            }
                        }
                    }
                    let tableRowNumber = Number($(row).find('span.rowNo').data('pctpRow'))
                    p.rowIndexCodePairs[tabName].push({
                        index: index,
                        code: code,
                        tableRowIndex: tableRowNumber
                    })
                    if (p.rowNumCodePairs.some(r => r.code === code)) {
                        for (const pair of p.rowNumCodePairs) {
                            if (pair.code === code) {
                                pair.rowNum = tableRowNumber
                                break;
                            }
                        }
                    } else {
                        p.rowNumCodePairs.push({
                            code: code,
                            rowNum: tableRowNumber
                        })
                    }
                    if ($(`#tabtbl${tabName}`).find('tr').length) {
                        p.#runObserversEvents($(`#tabtbl${tabName}`), tabName, 'initialize', $(row));
                        if (!!p.realtimeDataRowController && p.realtimeDataRowController.dataRowRefManager[tabName]) {
                            p.realtimeDataRowController.dataRowRefManager[tabName].push(new DataRowRef(p.getBookingId(tabName, $(row)), $(row)));
                            $(row).attr('title', p.#clientId)
                        }
                    }
                },
                initComplete: function (settings, json) {
                    if (!$(`#${tabName}tabpaneloading`).hasClass('d-none')) $(`#${tabName}tabpaneloading`).addClass('d-none')
                    if (!$(`#${tabName}loading`).hasClass('d-none')) $(`#${tabName}loading`).addClass('d-none')
                    $(`#${tabName}tabpanecontent`).removeClass('d-none')
                    if (tabName === p.getActiveTabName()) $(`#${tabName}excel`).removeClass('d-none');
                },
                info: false,
                searching: false,
                pagingType: 'numbers',
                pageLength: this.#viewOptions.data_table_page_length,
                ordering: true,
                columnDefs: [
                    {
                        orderable: false,
                        targets: ['pod', 'billing', 'tp'].includes(tabName) ? [0, 1, 2] : (tabName !== 'summary' ? [0, 1] : [0])
                    }
                ],
                preDrawCallback: function (settings) {
                    if (!findTimer.isStarted()) {
                        $('span.findTimeElapsed').html('');
                        findTimer.start();
                    }
                    p.rowIndexCodePairs[tabName] = [];
                    setScreenLoading(true);
                    if (!!p.realtimeDataRowController) {
                        p.realtimeDataRowController.dataRowRefManager.clear(tabName);
                        if (!['summary', 'treasury'].includes(tabName)) p.realtimeDataRowController.cleanUp({ group: tabName })
                    }
                },
                drawCallback: async function (settings) {
                    if (settings.aoData.length) {
                        p.#constants = await p.getApiData({ doRefresh: true, prop: 'constants' }).then(data => data).catch(console.log)
                        if (p.#viewOptions.run_formulas_on_row_init) p.renderTableRowsFormula(tabName);
                    }
                    if (!!p.realtimeDataRowController && $(`#tabtbl${tabName}`).find('tr').length) {
                        if (p.realtimeDataRowController.dataRowRefManager[tabName] && !['summary', 'treasury'].includes(tabName)) {
                            p.realtimeDataRowController.register({
                                group: tabName,
                                ids: p.realtimeDataRowController.dataRowRefManager[tabName].map(item => item.code)
                            })
                        }
                    }
                    if (findTimer.isStarted() && !!p.viewOptions.enable_find_timer_display) {
                        const timerInfo = findTimer.stop(true);
                        $('span.findTimeElapsed').html(`Search took ${timerInfo} (${tabName.toUpperCase()} - ${settings.json.data.length} displayed rows)`);
                        $('#btnfind').attr('title', `Recent search took ${timerInfo} (${tabName.toUpperCase()} - ${settings.json.data.length} displayed rows)`)
                        setTimeout(() => {
                            $('span.findTimeElapsed').html('');
                        }, p.viewOptions.find_timer_display_duration_ms)
                    } else {
                        p.log(`Search took ${findTimer.stop(true)} (${tabName.toUpperCase()} - ${settings.json.data.length} displayed rows)`)
                    }
                    setScreenLoading(false, true);
                },
                footerCallback: function(row, data, start, end, display) {
                    const api = this.api();
                    const parseFloatValue = (val) => {
                        return Number(String(val).trim().replace(',', '')) || 0;
                    }
                    p.columnDefinitions[tabName].forEach((columnDefinition, i) => {
                        const columnIndex = tabName === 'summary' ? i + 1 : i + 2;
                        if (columnDefinition.columnType === 'FLOAT') {
                            const updateSummaryFooter = (api, columnIndex, jElements, parseFloatValue) => {
                                const floatDataArr = jElements.map(jElem => parseFloatValue(jElem.val() || jElem.text()));
                                const maxData = Math.max(...floatDataArr);
                                const minData = Math.min(...floatDataArr);
                                const sumData = floatDataArr.reduce((a, b) => a + b, 0);
                                const aveData = sumData / floatDataArr.length;
                                api.column(columnIndex).footer().innerHTML = `
                                    <div class="row d-flex">
                                        <div id="${tabName}-${columnIndex}" class="col column-summary">
                                            <span>SUM: </span><span>${p.formatAsMoney(sumData)}</span><br>
                                            <span>AVE: </span><span>${p.formatAsMoney(aveData)}</span><br>
                                            <span>MIN: </span><span>${p.formatAsMoney(minData)}</span><br>
                                            <span>MAX: </span><span>${p.formatAsMoney(maxData)}</span><br>
                                        </div>
                                    </div>
                                `;
                            }
                            const jElements = api.column(columnIndex, { page: 'current' }).data().toArray().map(a => $(a));
                            updateSummaryFooter(api, columnIndex, jElements, parseFloatValue);
                            const pctpModel = jElements[0]?.data('pctpModel');
                            if (!!pctpModel) {
                                if (!!!p.modelPostTriggers[tabName]) p.modelPostTriggers[tabName] = {}
                                p.modelPostTriggers[tabName] = {
                                    ...p.modelPostTriggers[tabName],
                                    [pctpModel]: () => {
                                        const updatedJElements = $(`#tabtbl${tabName} *[data-pctp-model="${pctpModel}"]`).toArray().map(a => $(a));
                                        updateSummaryFooter(api, columnIndex, updatedJElements, parseFloatValue);
                                    }
                                }
                            }
                        }
                    })
                }
            });
        } else {
            if (!$(`#${tabName}tabpaneloading`).hasClass('d-none')) $(`#${tabName}tabpaneloading`).addClass('d-none')
            if (!$(`#${tabName}loading`).hasClass('d-none')) $(`#${tabName}loading`).addClass('d-none')
            $(`#${tabName}tabpanecontent`).removeClass('d-none')
            if (!$(`#${tabName}excel`).hasClass('d-none')) $(`#${tabName}excel`).addClass('d-none');
        }
    }
    hasDataTable(tabName) {
        return $.fn.DataTable.isDataTable(`#tabtbl${tabName}`)
    }
    resetGroupChangeProps(tabName) {
        this.groupChangeProps[tabName] = {};
        this.isMainCheckboxChecked[tabName] = false;
        this.excludedRowsFromSelection[tabName] = [];
        this.selectedModifiedRows = this.selectedModifiedRows.filter(s => !s.includes(tabName));
        this.modifiedRows.forEach(m => { if (m.tab === tabName) m.rows = [] });
        this.renderCountTabUpdate(tabName);
        $(`#chkall${tabName}`).prop('checked', false);
    }
    async refreshDataRow(arg, doDraw = false, postProcessJRow = null) {
        const { tabName, rowCodes } = arg;
        for (const rowCode of rowCodes) {
            if (!this.rowIndexCodePairs[tabName].some(r => r.code === rowCode)) continue;
            const rowSetting = this.rowIndexCodePairs[tabName].filter(r => r.code === rowCode)[0]
            const data = await this.getApiData({ tab: tabName, code: rowCode, tableRowIndex: rowSetting.tableRowIndex }, 'fetchDataRow');
            const dt = $(`#tabtbl${tabName}`).DataTable()
            if (doDraw) {
                dt.row(rowSetting.index).data(data).draw()
            } else {
                dt.row(rowSetting.index).data(data)
            }
            const jRow = $(`#tabtbl${tabName}`).find(`tr[data-pctp-code="${rowCode}"]`)
            this.renderRowFormulas(tabName, jRow)
            this.unselectTableRow(jRow, jRow.find('input[type=checkbox]'))
            this.selectedModifiedRows = this.selectedModifiedRows.filter(z => z !== rowCode)
            this.renderCountTabUpdate(tabName);
            if (!!postProcessJRow) postProcessJRow(jRow)
        }
        this.selectedSapDataRows = this.selectedSapDataRows.filter(z => z.tab !== tabName)
        return true
    }
    refreshUpdatedRows(arg, callback = null) {
        let modifiedRowCode = [];
        for (const m of arg.rows) {
            for (const k in m.props) {
                if (Object.hasOwnProperty.call(m.props, k)) {
                    $(`#tabtbl${arg.tab}`).DataTable().$(`tr[data-pctp-code='${arg.tab}${m.Code}']`).each(function () {
                        let row = $(this);
                        let e = row.find(`*[data-pctp-model='${k}']`);
                        if (e.length) {
                            switch (e[0].localName) {
                                case 'span':
                                    e = p.setAnonymousElementValue(arg.tab, e, m.props[k])
                                    e.data('pctpValue', m.props[k])
                                    break;
                                default:
                                    e.data('pctpValue', m.props[k])
                                    break;
                            }
                            p.#runObserversEvents(row.parent().parent(), arg.tab, 'update', row);
                            modifiedRowCode.push(m.Code);
                        }
                        p.unselectTableRow(row, row.find('input[type=checkbox]'))
                    });
                }
            }
        }
        for (const modifiedRow of this.modifiedRows) {
            if (modifiedRow.tab === arg.tab) {
                modifiedRow.rows = []
            }
        }
        this.childUpdateRow = this.childUpdateRow.filter(c => !modifiedRowCode.includes(c.parent))
        this.selectedModifiedRows = this.selectedModifiedRows.filter(s => !s.includes(arg.tab))
        this.selectedSapDataRows = this.selectedSapDataRows.filter(z => !modifiedRowCode.includes(z.Code));
        this.renderCountTabUpdate(arg.tab)
        if (arg.rDataRows !== undefined) {
            this.refreshUpdatedRowsFromTab(arg.rDataRows);
        }
        if (arg.uploadedAttachment !== undefined) {
            this.#uploadedAttachment = arg.uploadedAttachment;
        }
        if (callback !== null) {
            callback();
        }
        if (this.isMainCheckboxChecked[arg.tab] && Object.keys(this.groupChangeProps[arg.tab]).length) {
            this.resetGroupChangeProps(arg.tab)
        }
    }
    refreshUpdatedRowsFromTab(dataRows, rowData = null) {
        let rowCodes = [];
        for (const d of dataRows) {
            if (!this.hasDataTable(d.tab)) return;
            for (const m of d.rows) {
                for (const k in m.props) {
                    if (Object.hasOwnProperty.call(m.props, k)) {
                        $(`#tabtbl${d.tab}`).DataTable().$(`tr[data-pctp-code='${d.tab}${m.Code}']`).each(function () {
                            let row = $(this);
                            let e = row.find(`*[data-pctp-model='${k}']`);
                            if (e.length) {
                                switch (e[0].localName) {
                                    case 'span':
                                        e = p.setAnonymousElementValue(d.tab, e, m.props[k])
                                        e.data('pctpValue', m.props[k])
                                        break;
                                    default:
                                        e.data('pctpValue', m.props[k])
                                        break;
                                }
                                p.renderRowFormulas(d.tab, row)
                                p.unselectTableRow(row, row.find('input[type=checkbox]'))
                                rowCodes.push(`${d.tab}${m.Code}`);
                            }
                        });
                    }
                }
            }
            this.selectedSapDataRows = this.selectedSapDataRows.filter(z => z.tab !== d.tab)
            this.selectedModifiedRows = this.selectedModifiedRows.filter(z => !rowCodes.includes(z))
            this.renderCountTabUpdate(d.tab);
        }
    }
    showError(message) {
        portalMessage(message, 'red', 'white');
    }
    showSuccess(message) {
        portalMessage(message, '#00FF7F', 'black');
    }
    showInfo(message, timeout = -1) {
        portalMessage(message, 'lightblue', 'black', timeout);
    }
    hidePortalMessage(timeout = 0) {
        setTimeout(() => {
            $('#messageBar').text('').css({ 'background-color': '', 'color': '' });
            $('#messageBar2').removeClass('d-none');
        }, timeout);
    }
    clearElementValue(arg) {
        const { activeTabName, jElement } = arg;
        this.setAnonymousElementValue(activeTabName, jElement, '')
    }
    clearOtherElementValue(arg) {
        const { row, targetField, activeTabName } = arg;
        this.setAnonymousElementValue(activeTabName, row.find(`[data-pctp-model="${targetField}"]`), '')
    }
    getColumnDefinition(tab, fieldName) {
        return this.#columnDefinitions[tab].filter(f => f.fieldName === fieldName || f.fieldName === `_${fieldName}`)[0];
    }
    disableFields(arg) {
        const { row, fieldNames, activeTabName } = arg;
        for (const fieldName of fieldNames) {
            let e = row.find(`input[data-pctp-model="${fieldName.replace(/^_/, '')}"]`);
            if (!e.length) {
                e = row.find(`select[data-pctp-model="${fieldName.replace(/^_/, '')}"]`)
            }
            if (e.length) {
                let newTdHtml = '';
                let backgroundColor = row.hasClass('selected') ? this.viewOptions.selection_background_color : this.#viewOptions.td_background_color;
                newTdHtml += `<td style="vertical-align: middle; background-color: ${backgroundColor};">`;
                newTdHtml += `<span data-pctp-model="${e.data('pctpModel')}" data-pctp-value="${e.data('pctpValue')}">${e.val() == null ? '' : this.formatModelValue(activeTabName, e, e.val())}</span>`
                newTdHtml += `</td>`;
                this.getCell(e).replaceWith(newTdHtml);
            }
        }
    }
    enableFields(arg) {
        for (const fieldName of arg.fieldNames) {
            let e = arg.row.find(`span[data-pctp-model='${fieldName.replace(/^_/, '')}']`);
            if (e.length) {
                const columnDefinition = this.#columnDefinitions[arg.activeTabName].filter(f => f.fieldName === fieldName)[0];
                let newTdHtml = '';
                newTdHtml += `<td style="vertical-align: middle; ${columnDefinition.columnType === 'DATE' ? 'min-width: 155px;' : ''}">`;
                let data = arg?.retainCurrentData ? ((p, jElement, columnDefinition) => {
                    const jElementValue = e.val() || e.text();
                    if (this.isValidData(String(jElementValue).trim()) 
                        && (columnDefinition.columnType === 'FLOAT' && Number(String(jElementValue).replace(',', '')) !== 0)) {
                        return columnDefinition.columnType === 'FLOAT' ? Number(String(jElementValue).replace(',', '')) : jElementValue
                    }
                    return e.data('pctpValue')
                })(this, e, columnDefinition) : e.data('pctpValue');
                let dataHtml = e.html();
                let placeHolder = 'No data';
                let events = '';
                if (this.#columnValidations[arg.activeTabName] !== undefined
                    && this.#columnValidations[arg.activeTabName][fieldName] !== undefined) {
                    const columnValidation = this.#columnValidations[arg.activeTabName][fieldName].events;
                    for (const eventType in columnValidation) {
                        if (Object.hasOwnProperty.call(columnValidation, eventType)) {
                            const eventOptions = columnValidation[eventType];
                            events += ` ${eventType}="fieldEvent($(this), '${eventType}')" `;
                        }
                    }
                }
                // if (isset($model -> getColumnValidations()[$tabKeyword][$fieldName])) {
                //     foreach($model -> getColumnValidations()[$tabKeyword][$fieldName] -> events as $eventType => $eventOptions) {
                //         $events.= ' '.$eventType. '="fieldEvent($(this), \''.$eventType. '\')" ';
                //     }
                // }
                let formula = '';
                if (/^_\S+$/.test(columnDefinition.fieldName)) {
                    formula = `data-pctp-formula="${columnDefinition.fieldName}"`;
                }
                // if (preg_match('/^_\S+$/', $columnDefinition -> fieldName)) {
                //     $formula = 'data-pctp-formula="'.$columnDefinition -> fieldName. '"';
                // }
                let constant = '';
                const fieldEnumValues =  this.#fieldEnumValues[arg.activeTabName];
                if (fieldEnumValues !== undefined && Object.keys(fieldEnumValues).length) {
                    if (fieldEnumValues.fields.includes(fieldName)) {
                        constant = `data-pctp-check="${fieldEnumValues.enum}"`;
                    }
                }
                // if (isset($modelTab -> fieldEnumValues) && (bool)((array)$modelTab -> fieldEnumValues)) {
                //     if (in_array($columnDefinition -> fieldName, $modelTab -> fieldEnumValues -> fields)) {
                //         $enum = $modelTab -> fieldEnumValues ->enum;
                //         $constant = 'data-pctp-check="'.$enum. '"';
                //     }
                // }
                $
                let cascade = '';
                switch (fieldName) {
                    case 'SAPClient':
                        cascade = 'data-pctp-cascade="ClientName,GroupProject"';
                        break;
                    case 'SAPTrucker':
                        cascade = 'data-pctp-cascade="TruckerName"';
                        break;
                    default:
                        // code...
                        break;
                }
                // switch ($columnDefinition->fieldName) {
                //     case 'SAPClient':
                //         $cascade = 'data-pctp-cascade="ClientName,GroupProject"';
                //         break;
                //     case 'SAPTrucker':
                //         $cascade = 'data-pctp-cascade="TruckerName"';
                //         break;
                //     default:
                //         # code...
                //         break;
                // }
                let groupChange = '';
                if (columnDefinition.isGroupChange) {
                    groupChange = 'data-pctp-group-change';
                }
                // if ($columnDefinition -> isGroupChange) {
                //     $groupChange = 'data-pctp-group-change';
                // }
                let exclude = '';
                const foreignFields = this.#foreignFields[arg.activeTabName];
                if (!!!arg?.canBeUpdate && foreignFields !== undefined && foreignFields.length && foreignFields.includes(columnDefinition.fieldName)) {
                    exclude = 'data-pctp-update-exclude';
                }
                let forceUpdate = '';
                if (!!arg?.canBeUpdate && foreignFields !== undefined && foreignFields.length && foreignFields.includes(columnDefinition.fieldName)) {
                    forceUpdate = 'data-pctp-update-force';
                }
                // if ((bool)$modelTab -> foreignFields && in_array($columnDefinition -> fieldName, $modelTab -> foreignFields)) {
                //     $exclude = 'data-pctp-update-exclude';
                // }
                const additionalDataAtttributes = [
                    formula,
                    events,
                    constant,
                    cascade,
                    groupChange,
                    exclude,
                    forceUpdate,
                ].filter(s => s !== undefined).join(' ');
                switch (columnDefinition.columnViewType) {
                    case 'DROPDOWN':
                        let options = this.#dropDownOptions[columnDefinition.options];
                        newTdHtml += `<select onchange="fieldOnchange($(this))" data-pctp-model="${e.data('pctpModel')}" data-pctp-value="${data}" 
                                        class="edit-field" id="sel${e.data('pctpModel').toLowerCase()}" 
                                        style="width: 100%;" data-pctp-options="${columnDefinition.options}">`
                        newTdHtml += `<option value=""></option>`;
                        if (!options.filter(o => o.Code === data || o.Name === data).length && this.isValidData(data) && data !== 'null') {
                            newTdHtml += `<option value="${data}" selected>${data}</option>`;
                        } else {
                            newTdHtml += `<option value="" style="display: none;" disabled selected>Select...</option><option value=""></option>`
                        }
                        for (const option of options) {
                            newTdHtml += `<option value="${option.Code}" ${option.Name === data || option.Code === data ? 'selected' : ''}>${option.Name}</option>`
                        }
                        newTdHtml += `</select>`
                        break;
                    default:
                        let inputType;
                        let inputValue = '';
                        let inputPlaceholder = '';
                        let alignment = 'left';
                        let inputHeight = '30px';
                        switch (columnDefinition.columnType) {
                            case 'DATE':
                                inputType = 'date';
                                if (this.isValidData(data)) {
                                    inputValue = this.SQLDateFormater(data);
                                } else {
                                    inputValue = '';
                                }
                                alignment = 'center';
                                break;
                            case 'INT':
                            case 'FLOAT':
                                inputType = 'number';
                                alignment = 'right';
                                if (columnDefinition.fieldName) {
                                    if (!this.isValidData(data)) {
                                        inputPlaceholder = placeHolder;
                                    } else {
                                        inputValue = data;
                                    }
                                } else {
                                    inputPlaceholder = placeHolder;
                                }
                                break;
                            default:
                                inputType = 'text';
                                alignment = 'left';
                                if (columnDefinition.fieldName) {
                                    if (!this.isValidData(data)) {
                                        inputPlaceholder = placeHolder;
                                    } else {
                                        inputValue = data;
                                    }
                                } else {
                                    inputPlaceholder = placeHolder;
                                }
                                break;
                        }
                        if (columnDefinition.columnType === 'DATE') {
                            newTdHtml += `<div style="height: ${inputHeight}; vertical-align: middle;" class="col-12 input-group m-0 p-0">
                                <input type="text" class="col dateInputFace" style="text-align: ${alignment}; box-sizing: border-box;" 
                                    value="${inputValue ? inputValue : ''}">
                                <input ${additionalDataAtttributes} ${events ? 'data-pctp-observer' : ''} ${events} 
                                    ${!events.includes('onchange') ? 'onchange="fieldOnchange($(this))"' : ''} 
                                    data-pctp-model="${fieldName}" 
                                    data-pctp-value="${inputValue ? inputValue : ''}" 
                                    class="edit-field dateInputVal" 
                                    style="width: 30px; box-sizing: border-box; text-align: ${alignment};" 
                                    type="${inputType}" 
                                    value="${inputValue ? inputValue : ''}" 
                                    data-pctp-row-parent-distance="3"
                                >
                            </div>`
                        } else {
                            newTdHtml += `<input ${additionalDataAtttributes} 
                                data-pctp-type="${columnDefinition.columnType}" 
                                ${events !== '' ? 'data-pctp-observer' : ''} 
                                ${!events.includes('onchange') ? 'onchange="fieldOnchange($(this))"' : ''}  
                                data-pctp-model="${fieldName}" 
                                data-pctp-value="${inputValue || inputValue == 0 ? inputValue : ''}" 
                                class="edit-field" style="height: ${inputHeight}; width: 100%; box-sizing: border-box; text-align: ${alignment};" 
                                type="${inputType}" value="${inputValue || inputValue == 0 ? inputValue : ''}" 
                                ${inputPlaceholder ? 'placeholder="' + inputPlaceholder + '"' : ''}
                            >`
                        }
                        break;
                }
                newTdHtml += `</td>`;
                e.parent().replaceWith(newTdHtml);
            }
        }
    }
    decodeHtml(html) {
        let txt = document.createElement("textarea");
        txt.innerHTML = html;
        return txt.value;
    }
    isAnObservee(jElement, tab, eventType) {
        let columnValidations = this.#columnValidations[tab];
        if (columnValidations === undefined) return false;
        let field = jElement.data('pctpModel');
        if (columnValidations[field] !== undefined) return true;
        for (const observerField in columnValidations) {
            if (Object.hasOwnProperty.call(columnValidations, observerField)) {
                const observerFieldValidation = columnValidations[observerField];
                if (observerFieldValidation === undefined || observerFieldValidation.events === undefined) return false;
                let targetFieldEventOptions = observerFieldValidation.events[eventType];
                if (targetFieldEventOptions === undefined || !targetFieldEventOptions.length) return false;
                let targetFieldEventOptionFound = targetFieldEventOptions.filter(t => t.observee.fields.includes(field));
                if (targetFieldEventOptionFound !== undefined && targetFieldEventOptionFound.length) return true;
            }
        }
        return false;
    }
    getBookingId(tab, row) {
        let modelValue = this.getElementModelValue(tab, row, 'BookingId')
        if (modelValue !== null) {
            return String(modelValue).trim()
        } else {
            modelValue = this.getElementModelValue(tab, row, 'BookingNumber')
            if (modelValue !== null) {
                return String(modelValue).trim()
            }
        }
    }
    parseDataRow(row, tab, dontConsiderChanges = false) {
        let data = {}, props = {}, old = {};
        data['tab'] = tab;
        data['rowNum'] = row.find('span.rowNo').data('pctpRow');
        data['rowCode'] = row.data('pctpCode');
        data['Code'] = this.getRowCode(tab, row);
        data['BookingId'] = this.getBookingId(tab, row)
        data['forceUpdateFields'] = [];
        row.find('a[data-pctp-model]:not([data-pctp-formula],[data-pctp-update-exclude])').each(function () {
            let attachmentObj = p.uploadedAttachment[tab][row.data('pctpCode')];
            if (p.isValidData(attachmentObj) && $(this).data('pctpValue') != attachmentObj.attachment) {
                props[$(this).data('pctpModel')] = attachmentObj.attachment;
                old[$(this).data('pctpModel')] = $(this).data('pctpValue');
                data['upload'] = attachmentObj.upload;
                data['uploaded'] = attachmentObj.uploaded;
            }
        })
        row.find('input.edit-field:not([data-pctp-update-exclude])').each(function () {
            if (dontConsiderChanges || String($(this).data('pctpValue')).replace(/\s/g, '') != String($(this).val()).replace(/\s/g, '')) {
                const model = $(this).data('pctpModel');
                props[model] = $(this).val();
                if (!dontConsiderChanges) old[model] = $(this).data('pctpValue');
                if ($(this).data('pctpUpdateForce') !== undefined) {
                    data['forceUpdateFields'].push(model);
                }
            }
        })
        row.find('select.edit-field:not([data-pctp-update-exclude])').each(function () {
            if (dontConsiderChanges || String($(this).data('pctpValue')).replace(/\s/g, '') != String($(this).find(":selected").val()).replace(/\s/g, '')) {
                props[$(this).data('pctpModel')] = $(this).find(":selected").val();
                if (!dontConsiderChanges) old[$(this).data('pctpModel')] = $(this).data('pctpValue');
            }
        })
        row.find('span[data-pctp-model]:not([data-pctp-update-exclude])').each(function () {
            let htmlTextValue = p.decodeHtml($(this).html());
            const columnDefinition = p.getColumnDefinition(tab, $(this).data('pctpModel'));
            let formattedHtmlValue = p.formatValue(columnDefinition.columnType, htmlTextValue, false)
            let formattedModelValue = p.formatValue(columnDefinition.columnType, $(this).data('pctpValue'), false)
            let trimmedFormattedHtmlValue = String(formattedHtmlValue).replace(/\s/g, '');
            let trimmedFormattedModelValuee = String(formattedModelValue).replace(/\s/g, '');
            if (dontConsiderChanges) {
                props[$(this).data('pctpModel')] = formattedHtmlValue;
            } else if ((trimmedFormattedModelValuee != trimmedFormattedHtmlValue && columnDefinition.columnType !== 'INT')
                || (columnDefinition.columnType === 'INT' && trimmedFormattedModelValuee != trimmedFormattedHtmlValue
                && trimmedFormattedModelValuee !== '' && trimmedFormattedHtmlValue !== 0)) {
                props[$(this).data('pctpModel')] = formattedHtmlValue;
                old[$(this).data('pctpModel')] = formattedModelValue;
            }
        })
        if (dontConsiderChanges || Object.keys(props).length) {
            data['props'] = props;
            if (!dontConsiderChanges) data['old'] = old;
        }
        return data;
    }
    async fieldOnchange(jElement, tab = this.getActiveTabName()) {
        if (jElement.data('pctpCheck') !== undefined) {
            if (!this.#constants[jElement.data('pctpCheck')].includes(jElement.val())) {
                this.showError(`Invalid value '${jElement.val()}', not found from '${jElement.data('pctpCheck')}'`);
                p.refreshDataValue(jElement)
                return;
            }
        }
        let row = this.getRow(jElement);
        let data = this.parseDataRow(row, tab);
        this.log(data)
        this.addModifiedRow(data, tab);
        if (this.doConstantsNeedRefresh) {
            this.log('constants have been refreshed')
            try {
                this.#constants = await this.getApiData({ doRefresh: true, prop: 'constants' })
            } catch (error) {
                console.log(error)
            }
            this.doConstantsNeedRefresh = false
            setTimeout(() => { p.doConstantsNeedRefresh = true; p.log('doConstantsNeedRefresh has now been set to true') }, this.#viewOptions.constants_refresh_waiting_time)
        }
        this.renderRowFormulas(tab, row);
        const elemModel = jElement.data('pctpModel')
        if (this.isAnObservee(jElement, tab, 'onchange')) { console.log(`run observer events runner by ${elemModel}`); fieldEvent(jElement, 'onchange', tab); }
        !!this.modelPostTriggers[tab]?.[elemModel] && this.modelPostTriggers[tab][elemModel]()
    }

    getRow(jElement) {
        let element = jElement;
        if (jElement.data('pctpRowParentDistance') !== undefined) {
            for (let index = 0; index < Number(jElement.data('pctpRowParentDistance')); index++) {
                element = element.parent();
            }
            return element;
        }
        for (let index = 0; index < this.#viewOptions.child_parent_step_distance; index++) {
            element = element.parent();
        }
        return element;
    }
    getCell(jElement) {
        let element = jElement;
        if (jElement.data('pctpRowParentDistance') !== undefined) {
            for (let index = 0; index < Number(jElement.data('pctpRowParentDistance')) - 1; index++) {
                element = element.parent();
            }
            return element;
        }
        for (let index = 0; index < this.#viewOptions.child_parent_step_distance - 1; index++) {
            element = element.parent();
        }
        return element;
    }
    getActiveTabName() {
        return $('div.tab-pane.active').data('pctpModel');
    }
    changeFieldValueFromOtherTab(prop) {
        if (!prop.bool) return;
        const { jElement, row, tab, refField, otherTab, foreignField, field, value, doRefreshDataRow } = prop;
        let refValue = null;
        row.find(`*[data-pctp-model="${refField.replace(/^_/, '')}"]`).each(function () {
            refValue = p.getFormattedModelValue(tab, $(this), refField);
            return false;
        })
        if (!this.hasDataTable(otherTab)) return;
        $(`#tabtbl${otherTab}`).DataTable().$('tr').each(function () {
            let hasFound = false;
            let oRow = $(this);
            oRow.find(`*[data-pctp-model="${foreignField.replace(/^_/, '')}"]`).each(async function () {
                let foreignValue = p.getFormattedModelValue(otherTab, $(this), foreignField);
                if (foreignValue == refValue) {
                    if (doRefreshDataRow && foreignField === 'Code') {
                        let targetRowCode = `${otherTab}${foreignValue}`;
                        let props = {}
                        props[field.replace(/^_/, '')] = value === 'self' ? p.getAnonymousElementValue(jElement) : value;
                        p.transientChanges[targetRowCode] = props;
                        p.refreshDataRow({
                            tabName: otherTab,
                            rowCodes: [targetRowCode]
                        }, true)
                        return false;
                    } else {
                        let targetElement = oRow.find(`*[data-pctp-model="${field.replace(/^_/, '')}"]`)
                        if (targetElement.length) {
                            if (value === 'self') {
                                targetElement = p.setAnonymousElementValue(otherTab, targetElement, p.getAnonymousElementValue(jElement));
                            } else {
                                targetElement = p.setAnonymousElementValue(otherTab, targetElement, value);
                            }
                            p.fieldOnchange(targetElement, otherTab);
                            hasFound = true;
                            p.childUpdateRow.push({ parent: row.data('pctpCode'), child: oRow.data('pctpCode') })
                            return false;
                        }
                    }
                    p.log(`Cannot find target element with field '${field}'`);
                    return false;
                }
            })
            if (hasFound) return false;
        })

    }
    changeFieldValueFromOtherTabByFormula(prop) {
        if (!prop.bool) return;
        const {
            jElement,
            row,
            tab,
            refField,
            otherTab,
            foreignField,
            field,
            formula,
            useFormulaInsideRow,
            updateConstantName,
            relatedUpdateMonitor
        } = prop;

        if (updateConstantName !== undefined) {
            this.updateConstant(prop);
        }

        let refValue = null;
        row.find(`*[data-pctp-model="${refField.replace(/^_/, '')}"]`).each(function () {
            refValue = p.getFormattedModelValue(tab, $(this), refField);
            return false;
        })
        if (useFormulaInsideRow !== undefined && useFormulaInsideRow) relatedUpdateMonitor(row, field, formula, p.getFormulas(row)[formula]());
        if (!this.hasDataTable(otherTab)) return;
        $(`#tabtbl${otherTab}`).DataTable().$('tr').each(function () {
            let hasFound = false;
            let oRow = $(this);
            oRow.find(`*[data-pctp-model="${foreignField.replace(/^_/, '')}"]`).each(function () {
                let foreignValue = p.getFormattedModelValue(otherTab, $(this), foreignField);
                if (foreignValue == refValue) {
                    let targetElement = oRow.find(`*[data-pctp-model="${field.replace(/^_/, '')}"]`)
                    if (targetElement.length) {
                        let value = p.getFormulas(useFormulaInsideRow !== undefined && useFormulaInsideRow ? row : oRow)[formula]();
                        targetElement = p.setAnonymousElementValue(otherTab, targetElement, value);
                        p.fieldOnchange(targetElement, otherTab);
                        hasFound = true;
                        p.childUpdateRow.push({ parent: row.data('pctpCode'), child: oRow.data('pctpCode') })
                        return false;
                    }
                    p.log(`Cannot find target element with field '${field}'`);
                    return false;
                }
            })
            if (hasFound) return false;
        })
    }
    promptMessage2Buttons2ReturnBools(arg) {
        this.log(arg)
        const { row, title, message, button1Label, button2Label, prop, info, callback, isOutsideCallback } = arg;
        let appendedProp = { row: row, ...prop };
        $('#promptTitle').html(title);
        $('#promptMessage').html(message);
        if (this.isValidData(info)) {
            $('#promptInfo').removeClass('d-none');
            $('#promptInfo').html(info);
        } else
            $('#promptInfo').addClass('d-none');
        $('#btnPrompt1').removeClass('d-none');
        $('#btnPrompt1').html(button1Label);
        $('#btnPrompt2').removeClass('d-none');
        $('#btnPrompt2').html(button2Label);
        $('#promptModal').modal('show');
        $('#btnPrompt1').off('click').click(function () {
            if (isOutsideCallback) {
                if (p.isValidData(callback)) {
                    if (Object.keys(appendedProp).length)
                        callback({ bool: true, ...appendedProp });
                    else
                        callback(true);
                }
            } else {
                if (p.isValidData(callback)) {
                    if (Object.keys(appendedProp).length)
                        p[callback]({ bool: true, ...appendedProp });
                    else
                        p[callback](true);
                }
            }
        });
        $('#btnPrompt2').off('click').click(function () {
            if (isOutsideCallback) {
                if (p.isValidData(callback)) {
                    if (Object.keys(appendedProp).length)
                        callback({ bool: false, ...appendedProp });
                    else
                        callback(false);
                }
            } else {
                if (p.isValidData(callback)) {
                    if (Object.keys(appendedProp).length)
                        p[callback]({ bool: false, ...appendedProp });
                    else
                        p[callback](false);
                }
            }
        });
    }
    promptMessage1Button(arg) {
        const { title, message, button1Label, info } = arg;
        $('#promptTitle').html(title);
        $('#promptMessage').html(message);
        if (p.isValidData(info)) {
            $('#promptInfo').html(info);
            $('#promptInfo').removeClass('d-none');
        }
        else {
            if (!$('#promptInfo').hasClass('d-none'))
                $('#promptInfo').addClass('d-none');
        }
        $('#btnPrompt1').removeClass('d-none');
        $('#btnPrompt1').html(button1Label);

        if (!$('#btnPrompt2').hasClass('d-none'))
            $('#btnPrompt2').addClass('d-none');

        $('#promptModal').modal('show');

        $('#btnPrompt1').off('click').click(function () {
            $('#promptModal').modal('hide');
            setTimeout(() => {
                $('#btnPrompt2').removeClass('d-none');
                $('#promptInfo').removeClass('d-none');
            }, 200);
        });
    }
    findTableRow(rowCode) {
        let tabName = rowCode.replace(/\d+/, '')
        return $(`#tabtbl${tabName}`).DataTable().$(`tr[data-pctp-code="${rowCode}"]`)
    }
    findTableRowByFieldValue(tabName, fieldName, fieldValue) {
        let jRow = null;
        $(`#tabtbl${tabName}`).DataTable().$(`td *[data-pctp-model="${fieldName}"]`).each(function () {
            if (String(p.getAnonymousElementValue($(this))).trim() === String(fieldValue).trim()) {
                jRow = p.getRow($(this));
                return false;
            }
        })
        return jRow;
    }
    validateAction(actionName) {
        if (this.#actionValidations.hasOwnProperty(actionName)) {
            const validation = this.#actionValidations[actionName].validation;
            let tab = this.getActiveTabName();
            let tabRows = this.getTabModifiedRows(tab).tabRows;
            for (const target of validation.targets) {
                if (target.tab === tab) {
                    if (tabRows.some(t => t.tab === tab)) {
                        for (const tabRow of tabRows) {
                            let row = $(`#tabtbl${tabRow.tab}`).DataTable().$(`tr[data-pctp-code="${tabRow.rowCode}"]`)
                            if (row.length && tabRow.props && tabRow.props[target.checkField] !== undefined) {
                                if (target.passedValues.includes(tabRow.props[target.checkField])) continue;
                                if (target.checkValues.length && !target.checkValues.includes(tabRow.props[target.checkField])) continue;
                                for (const evaluation of target.evaluations) {
                                    let arg = {
                                        row: row,
                                        ...evaluation.arg
                                    }
                                    let result = this[evaluation.callback](arg);
                                    if (result) {
                                        this.promptMessage1Button({
                                            title: 'ERROR',
                                            message: evaluation.failedMessage !== undefined ? evaluation.failedMessage : 'Something went wrong',
                                            button1Label: 'OK'
                                        })
                                        return false
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return true;
    }
    changeOtherField(arg) {
        const { row, jElement, field, value, activeTabName } = arg;
        let jOtherField = row.find(`*[data-pctp-model="${field.replace(/^_/, '')}"]`)
        if (value === 'self') {
            this.setAnonymousElementValue(activeTabName, jOtherField, this.getAnonymousElementValue(jElement));
        } else {
            this.setAnonymousElementValue(activeTabName, jOtherField, value);
        }
    }
    changeOtherFieldByFormula(arg) {
        const { row, field, formula, activeTabName } = arg;
        let jOtherField = row.find(`*[data-pctp-model="${field.replace(/^_/, '')}"]`)
        let value = this.getFormulas(row)[formula]();
        this.setAnonymousElementValue(activeTabName, jOtherField, value);
    }
    changeOtherFieldBasedOnFormerValue(arg) {
        const { row, field, formerValue, value, activeTabName } = arg;
        let jOtherField = row.find(`*[data-pctp-model="${field.replace(/^_/, '')}"]`)
        if (this.getAnonymousElementValue(jOtherField) == formerValue) this.setAnonymousElementValue(activeTabName, jOtherField, value);
    }
    deleteRowFromTable(arg) {
        const { tab, row } = arg;
        $(`#tabtbl${tab}`).DataTable()
            .row(row)
            .remove()
            .draw();
        this.refreshRowNumbers(tab);
    }
    getDateDefaultFormat(date) {
        let option = { args: { year: 'numeric', month: '2-digit', day: '2-digit' }, order: [4, 0, 2] };
        let dateObj = new Intl.DateTimeFormat('en-us', option.args).formatToParts(date);
        return `${dateObj[option.order[0]].value}-${dateObj[option.order[1]].value}-${dateObj[option.order[2]].value}`;
    }
    SAPDateFormater(dateLiteral) {
        let SAPDateFormat = Number(this.#constants.SAPDateFormat);
        let options = [
            { args: { year: '2-digit', month: '2-digit', day: '2-digit' }, order: [2, 0, 4] },
            { args: { year: 'numeric', month: '2-digit', day: '2-digit' }, order: [2, 0, 4] },
            { args: { year: '2-digit', month: '2-digit', day: '2-digit' }, order: [0, 2, 4] },
            { args: { year: 'numeric', month: '2-digit', day: '2-digit' }, order: [0, 2, 4] },
            { args: { year: 'numeric', month: '2-digit', day: '2-digit' }, order: [4, 0, 2] },
            { args: { year: 'numeric', month: 'long', day: '2-digit' }, order: [2, 0, 4] },
            { args: { year: '2-digit', month: '2-digit', day: '2-digit' }, order: [4, 0, 2] }
        ];
        dateLiteral = SAPDateFormat == 6 && dateLiteral.length == 8 ? '20' + dateLiteral : dateLiteral;
        let dateObj;
        try {
            let passDate = new Date(dateLiteral);
            if (passDate == 'Invalid Date') throw `Invalid date format. Cannot parse date value from string '${dateLiteral}'`;
            dateObj = new Intl.DateTimeFormat('en-us', options[SAPDateFormat].args).formatToParts(passDate);
        }
        catch (err) {
            throw err
        }
        return `${dateObj[options[SAPDateFormat].order[0]].value}.${dateObj[options[SAPDateFormat].order[1]].value}.${dateObj[options[SAPDateFormat].order[2]].value}`;
    }
    SQLDateFormater(dateLiteral) {
        if (dateLiteral == '') {
            return '';
        }
        let dateObj = new Intl.DateTimeFormat('en-us', { year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(new Date(dateLiteral));
        return `${dateObj[4].value}-${dateObj[0].value}-${dateObj[2].value}`;
    }
    async apiAjax(actionName, data, callback = null) {
        const d = await $.post('../res/api.php', { action: actionName, data: data });
        try {
            p.log('data-pctp-received', JSON.parse(d));
            let data_1 = JSON.parse(d);
            if (data_1.type !== undefined && data_1.type === 'error')
                throw data_1.message;
            if (data_1.result == 'success') {
                if (p.isValidData(data_1.callback)) {
                    p[data_1.callback](data_1.arg, callback === null ? null : () => callback());
                } else {
                    if (callback !== null) {
                        callback();
                    } else {
                        return data_1.resultData;
                    }
                }
            } else {
                if (callback !== null) {
                    callback();
                } else {
                    return data_1.resultData;
                }
            }
        } catch (error) {
            p.showError(error);
            p.log(error);
            p.log(d);
            if (callback !== null) {
                callback();
            }
        }
    }
    refreshModelElement(arg) {
        const { row, field } = arg;
        let jElement = row.find(`[data-pctp-model="${field}"]`)
        this.refreshDataValue(jElement)
    }
    refreshDataValue(jElem, jRow = null) {
        switch (jElem[0].localName) {
            case 'input':
                jElem.val(jElem.data('pctpValue'))
                break;
            case 'select':
                jElem.val(jElem.data('pctpValue'))
                break;
            case 'span':
                jElem.html(jElem.data('pctpValue'))
                break;
            default:
                break;
        }
        if (jRow !== null && jElem.data('pctpCascade') !== undefined) {
            let cascadeElems = jRow.find(`[data-pctp-model="${jElem.data('pctpCascade')}"]`)
            if (cascadeElems.includes(',')) {
                for (const cascadeElem of cascadeElems.split(',')) {
                    refreshDataValue(cascadeElem);
                }
            } else {
                refreshDataValue(cascadeElems);
            }
        }
    }
    refreshRowNumbers(tabName) {
        let rowNo = 0;
        $(`#tabtbl${tabName}`).DataTable().$('tr').each(function () {
            $(this).find('span.rowNo').html(++rowNo);
        })
    }
    getFormattedModelDataValue(tab, jElement, field) {
        let columnDefinition = this.#columnDefinitions[tab].filter(c => c.fieldName === field || c.fieldName === `_${field}`)[0];
        let modelDataValue = jElement.data('pctpValue');
        switch (columnDefinition.columnType) {
            case 'DATE':
                return new Date(modelDataValue) == 'Invalid Date' ? null : new Date(modelDataValue);
            case 'INT':
            case 'FLOAT':
                return Number(modelDataValue)
            default:
                return modelDataValue
        }
    }
    getFormattedModelValue(tab, jElement, field) {
        let columnDefinition = this.#columnDefinitions[tab].filter(c => c.fieldName === field || c.fieldName === `_${field}`)[0];
        let modelValue = this.getAnonymousElementValue(jElement);
        switch (columnDefinition.columnType) {
            case 'DATE':
                return new Date(modelValue) == 'Invalid Date' ? null : new Date(modelValue);
            case 'INT':
            case 'FLOAT':
                return Number(modelValue)
            default:
                return modelValue
        }
    }
    getElementModelValue(tab, jRow, field) {
        try {
            let columnDefinition = this.#columnDefinitions[tab].filter(c => c.fieldName === field || c.fieldName === `_${field}`)[0];
            let modelValue = this.getAnonymousElementValue(this.getElementModel(jRow, field));
            switch (columnDefinition.columnType) {
                case 'DATE':
                    return modelValue === null || new Date(modelValue) == 'Invalid Date' ? null : new Date(modelValue);
                case 'INT':
                case 'FLOAT':
                    modelValue = String(modelValue).replaceAll(',', '')
                    return Number(modelValue)
                default:
                    return modelValue
            }
        } catch (error) {
            this.log(error)
            return null
        }
    }
    getElementModel(jRow, field) {
        return jRow.find(`*[data-pctp-model="${field.replace(/^_/, '')}"]`)
    }
    getAnonymousElementValue(jElement) {
        switch (jElement[0].localName) {
            case 'input':
                return jElement.val()
            case 'select':
                return jElement.find(':selected').val();
            case 'a':
            case 'span':
                return this.decodeHtml(jElement.html())
            default:
                p.log(jElement.localName, jElement)
                throw 'Cannot find localName of anonymous element';
        }
    }
    setAnonymousElementValue(tab, jElement, value, doUpdatePersistedValue = false) {
        const modelValue = this.formatModelValue(tab, jElement, value);
        switch (jElement[0].localName) {
            case 'input':
            case 'select':
                jElement.val(modelValue)
                break;
            case 'a':
            case 'span':
                jElement.html(modelValue)
                break;
            default:
                p.log(jElement, jElement.localName, value)
                throw 'Cannot find localName of anonymous element';
        }
        if (doUpdatePersistedValue) {
            jElement.data('pctpValue', modelValue);
            p.log(tab, jElement.data('pctpModel'), jElement.data('pctpValue'))
        }
        return jElement;
    }
    formatModelValue(tab, jElement, value) {
        let columnDefinition = this.#columnDefinitions[tab]
            .filter(c => c.fieldName === jElement.data('pctpModel') || c.fieldName === `_${jElement.data('pctpModel')}`)[0];
        return this.formatValue(columnDefinition.columnType, value);
    }
    formatValue(columnType, value, isSapFormat = true) {
        try {
            switch (columnType) {
                case 'DATE':
                    return value === null || new Date(value) == 'Invalid Date' ? '' : (isSapFormat ? this.SAPDateFormater(new Date(value)) : this.SQLDateFormater(new Date(value)));
                case 'INT':
                    return value === null || value === '' ? '' : Number(value);
                case 'FLOAT':
                    if (!isSapFormat) value = String(value).replaceAll(',', '')
                    return isSapFormat ? this.formatAsMoney(Number(value)) : Number(value)
                default:
                    return value
            }
        } catch (error) {
            console.log(error)
            return value
        }
    }
    renderTableRowsFormula(tabName) {
        $(`#tabtbl${tabName}`).DataTable().$('tr').each(function () {
            p.renderRowFormulas(tabName, $(this));
        });
    }
    renderRowFormulas(tab, jRow) {
        if (!this.#viewOptions.run_formulas_on_row_init) return;
        jRow.find('*[data-pctp-formula]').each(function () {
            let jElement = $(this);
            let formula = jElement.data('pctpFormula');
            jElement = p.setAnonymousElementValue(
                tab,
                jElement,
                p.getFormulas(jRow)[formula]()
            )
        })
    }
    unselectTableRow(jTableRow, jCheckRow = null) {
        jTableRow.removeClass('selected')
        jTableRow.find('td').each(function () {
            $(this).css('background-color', jTableRow.hasClass('locked-data-row') ? p.viewOptions.locked_row_background_color : p.viewOptions.td_background_color)
        })
        if (jCheckRow !== null) jCheckRow.prop('checked', false);
    }
    formatAsMoney(amount) {
        amount = String(amount).replaceAll(',', '');
        if (amount === NaN || isNaN(amount)) p.log(`Cannot parse float from '${amount}'`);
        return accounting.formatMoney(Number(amount), '', this.#constants['SAPPriceDecimal']);
    }
    getValueFromOtherTab(jRow, otherTab, fieldName, ownField, foreignField) {
        let tab = this.getTab(jRow);
        let commonFieldValue = this.getElementModelValue(tab, jRow, ownField);
        let fElement = null;
        $(`#tabtbl${otherTab}`).DataTable.$(`tr *[data-pctp-model="${foreignField}"]`).each(function () {
            if (p.getAnonymousElementValue($(this)) == commonFieldValue) {
                fElement = $(this);
                return false;
            }
        })
        if (this.isValidData(fElement)) {
            return this.getFormattedModelValue(otherTab, fElement, fieldName)
        }
        p.log(`element with data '${foreignField}' not found`);
        return null
    }
    async getApiData(data, actionName = 'getData') {
        try {
            const resultJson = await $.post('../res/api.php', { action: actionName, data: data }).then((d) => d);
            const returnedData = resultJson === '' ? '' : JSON.parse(resultJson);
            if (returnedData === '') return ''
            p.log(returnedData)
            if (returnedData.result === 'success') {
                return returnedData.data;
            } else if (!!returnedData.type && returnedData.type === 'info') {
                return returnedData;
            } else {
                console.log(returnedData.message)
                return null;
            }
        } catch (error) {
            console.log(error)
            return ''
        }

    }
    async validateFieldApiData(arg, callback) {
        const { activeTabName, jElement, validation, fieldName, targetDataProp, evaluation, passedValues, passedResult } = arg
        const fieldValue = this.getAnonymousElementValue(jElement);
        if (passedValues.includes(fieldValue)) {
            callback(evaluation, arg, passedResult);
        } else {
            this.getApiData({ tab: activeTabName, validation: validation, arg: { fieldValue: fieldValue, fieldName: fieldName } }, 'validateData').then(data => {
                p.log(data)
                callback(evaluation, arg, data[targetDataProp]);
            }).catch(console.log)
        }
    }
    async changeOtherFieldApiData(arg) {
        const { row, jElement, field, data, value, dataField, targetField } = arg
        const targetElement = row.find(`*[data-pctp-model="${field}"]`)
        this.getApiData({ doRefresh: true, prop: 'apiData', data: data, field: dataField, value: value === 'self' ? jElement.val() : value }).then(data => {
            p.log(data)
            p.isValidData(data) ? p.setAnonymousElementValue(p.getActiveTabName(), targetElement, data[targetField]) : p.refreshDataValue(targetElement)
        }).catch(console.log)
    }
    updateConstant(arg) {
        const { row, updateConstantName, refField, fieldName, fieldValue, fieldFormula } = arg;
        let refValue = this.getValue(row, refField);
        for (const constantObj of this.#constants[updateConstantName]) {
            if (constantObj[refField] === refValue) {
                if (fieldFormula !== undefined) {
                    constantObj[fieldName] = this.getFormulas(row)[fieldFormula]();
                } else {
                    constantObj[fieldName] = fieldValue
                }
            }
        }
    }
    getValue(jRow, fieldName) {
        let tab = this.getTab(jRow);
        return this.getElementModelValue(tab, jRow, fieldName)
    }
    isDate1EarlierThanDate2(arg) {
        const { row, jElement, dateField1, dateField2 } = arg;
        let date1 = new Date()
        if (dateField1 === 'self') {
            date1 = this.getAnonymousElementValue(jElement)
        } else {
            date1 = this.getAnonymousElementValue(row.find(`[data-pctp-model="${dateField1}"]`))
        }
        let date2 = new Date()
        if (dateField2 === 'self') {
            date2 = this.getAnonymousElementValue(jElement)
        } else {
            date2 = this.getAnonymousElementValue(row.find(`[data-pctp-model="${dateField2}"]`))
        }
        if (!p.isValidData(date1) && !p.isValidData(date2)) return false;
        if (p.isValidData(date1) && !p.isValidData(date2)) return true;
        return (new Date(this.SQLDateFormater(date1)) - new Date(this.SQLDateFormater(date2))) < 0;
    }
    isEmpty(arg) {
        const { row, subjectField } = arg;
        return !this.isValidData(this.getAnonymousElementValue(row.find(`[data-pctp-model="${subjectField}"]`)))
    }
    isDataDuplicate(arg) {
        const { activeTabName, row, jElement, fieldName, passedValues, passedResult } = arg;
        let jElementValue = this.getAnonymousElementValue(jElement);
        let found = false;
        if (passedValues.includes(jElementValue)) {
            return passedResult
        }
        $(`#tabtbl${activeTabName}`).DataTable().$(`tr`).each(function () {
            let targetElement = $(this).find(`*[data-pctp-model="${fieldName}"]`)
            if (row.data('pctpCode') !== $(this).data('pctpCode')
                && jElementValue == p.getAnonymousElementValue(targetElement)) {
                found = true;
                return false
            }
        })
        return found;
    }
    validateTime(jElement) {
        if ((new RegExp('^((0?[0-9])|1\\d|2[0-3])(:)((0?[0-9])|[1-5][0-9])$')).test(jElement.val())) {
            let timeStrArr = jElement.val().split(':');
            jElement.val(`${timeStrArr[0].length > 1 ? timeStrArr[0] : `0${timeStrArr[0]}`}:${timeStrArr[1].length > 1 ? timeStrArr[1] : `0${timeStrArr[1]}`}`)
        } else {
            this.showError(`'${jElement.val()}' is not a valid time or a wrong 24Hour time format (HH:MM)`)
            jElement.val('')
        }
    }
    async createEventSource(source) {

    }
    async downloadExcel(tabName, jExcelIcon) {
        const fileName = `${tabName}-tab-excel`;
        if (!!this.#config.enable_excel_background_download) {
            this.getApiData({ 
                tab: tabName,
                fetchedIdsToProcess: !!this.fetchedIdsToProcess ? this.fetchedIdsToProcess.map(e => e.id) : null
             }, 'getTableRowsDataWithHeaders').then(async data => {
                if (!!data.type && data.type === 'info') {
                    const startTime = new Date();
                    jExcelIcon.css('animation', 'color-change .6s infinite linear')
                    const excelIconDiv = jExcelIcon.parent().parent();
                    p.showInfo(`Processing excel download in the background... (${p.fetchTableRowsCount[tabName]} row${Number(p.fetchTableRowsCount[tabName]) > 1 ? 's' : ''})`, 5000);
                    if (!!window.EventSource) {
                        const eventSource = new EventSource('../res/sse/api-sse.php');
                        p.tabSettings[tabName].hasExcelDownloadProcessing = true;
                        eventSource.addEventListener('open', function (event) {
                            p.log('SSE Connection has been opened.');
                        });
                        let arrayOfArrays = [];
                        eventSource.addEventListener('message', async function (event) {
                            try {
                                const dataObj = JSON.parse(event.data);
                                if (dataObj.test) throw 'Test only';
                                switch (dataObj.status) {
                                    case 'ongoing':
                                        arrayOfArrays = [...arrayOfArrays, ...dataObj.data.data];
                                        break;
                                    case 'complete':
                                        arrayOfArrays = [...arrayOfArrays, ...dataObj.data.data];
                                        p.produceExcelFile(arrayOfArrays, `${tabName}-tab-excel`).then(result => {
                                            const endTime = new Date();
                                            const timeDiffInMin = ((endTime - startTime) / 1000) / 60;
                                            const timeDiffInSec = ((endTime - startTime) / 1000);
                                            p.log(Math.round(timeDiffInSec) + " seconds");
                                            p.log(Math.round(timeDiffInMin) + " minutes");
                                            const timeDesc = Math.round(timeDiffInMin) === 0 ? `${Math.round(timeDiffInSec)} sec elapsed`
                                                : `${Math.round(timeDiffInMin)} min elapsed`
                                            const infoDesc = `${p.fetchTableRowsCount[tabName]} row${Number(p.fetchTableRowsCount[tabName]) > 1 ? 's' : ''}`;
                                            promptMessage1Button(
                                                'PCTP Window Notification',
                                                `File '${fileName}' is now downloaded. (${timeDesc}, extracting ${infoDesc})`,
                                                'OK',
                                            )
                                            p.log('Closing SSE connection...')
                                            eventSource.close();
                                            p.log('SSE connection is now closed.')
                                            jExcelIcon.css('animation', 'none')
                                            p.tabSettings[tabName].hasExcelDownloadProcessing = false;
                                            if (p.getActiveTabName() !== tabName) excelIconDiv.addClass('d-none')
                                        });
                                        break;
                                    default:
                                        break;
                                }
                            } catch (error) {
                                p.log(error);
                                p.log('Closing SSE connection...')
                                eventSource.close();
                                p.log('SSE connection is now closed.')
                                jExcelIcon.css('animation', 'none')
                                p.tabSettings[tabName].hasExcelDownloadProcessing = false;
                                if (p.getActiveTabName() !== tabName) excelIconDiv.addClass('d-none')
                            }
                        });
                        eventSource.addEventListener('error', function (error) {
                            const endTime = new Date();
                            const timeDiffInMin = ((endTime - startTime) / 1000) / 60;
                            const timeDiffInSec = ((endTime - startTime) / 1000);
                            p.log(Math.round(timeDiffInSec) + " seconds");
                            p.log(Math.round(timeDiffInMin) + " minutes");
                            const timeDesc = Math.round(timeDiffInMin) === 0 ? `${Math.round(timeDiffInSec)} sec elapsed`
                                : `${Math.round(timeDiffInMin)} min elapsed`
                            p.log(`${arrayOfArrays.length} processed rows (${timeDesc})`);
                            promptMessage1Button(
                                'Error',
                                error,
                                'OK',
                            )
                            p.log(error);
                            p.log('Closing SSE connection...')
                            eventSource.close();
                            p.log('SSE connection is now closed.')
                            jExcelIcon.css('animation', 'none')
                            p.tabSettings[tabName].hasExcelDownloadProcessing = false;
                            if (p.getActiveTabName() !== tabName) excelIconDiv.addClass('d-none')
                        });
                    } else {
                        promptMessage1Button(
                            'Error',
                            'Your browser does not support server-sent events.',
                            'OK',
                        )
                        p.showError('Cannot process excel download in the background, will process synchronously...');
                        await timeout(3000);
                        const arrayOfArrays = await p.getApiData({ tab: tabName }, 'getTableRowsDataWithHeaders');
                        p.produceExcelFile(arrayOfArrays, fileName);
                    }
                } else {
                    p.showError('Cannot process excel download in the background, will process synchronously...');
                    await timeout(3000);
                    const arrayOfArrays = await p.getApiData({ tab: tabName }, 'getTableRowsDataWithHeaders');
                    p.produceExcelFile(arrayOfArrays, fileName);
                }
            })
        } else {
            const arrayOfArrays = await this.getApiData({ tab: tabName }, 'getTableRowsDataWithHeaders');
            this.produceExcelFile(arrayOfArrays, fileName);
        }
    }

    async produceExcelFile(arrayOfArrays, fileName) {
        var wb = XLSX.utils.book_new();
        wb.Props = {
            Title: "Table to Excel",
            Subject: "Export",
            Author: "User",
            CreatedDate: new Date()
        };
        wb.SheetNames.push(fileName);
        var ws_data = arrayOfArrays;
        var ws = XLSX.utils.aoa_to_sheet(ws_data);
        wb.Sheets[fileName] = ws;
        var wbout = XLSX.write(wb, { bookType: 'xlsx', type: 'binary' });
        function s2ab(s) {
            var buf = new ArrayBuffer(s.length); //convert s to arrayBuffer
            var view = new Uint8Array(buf);  //create uint8array as viewer
            for (var i = 0; i < s.length; i++) view[i] = s.charCodeAt(i) & 0xFF; //convert to octet
            return buf;
        }
        saveAs(new Blob([s2ab(wbout)], { type: "application/octet-stream" }), fileName + '.xlsx');
        return true;
    }

    getTab(jRow) {
        if (!this.isValidData(jRow.data('pctpCode'))) throw `'${this.getBookingId(this.getActiveTabName(), jRow)}' might be missing from the main table of ${this.getActiveTabName().toUpperCase()}. Cannot modify this row`;
        return jRow.data('pctpCode').replace(/[\d|A-Z]+/, '');
    }
    getFormulas(jRow) {
        return {
            jRow: jRow,
            oneDayInMs: 24 * 60 * 60 * 1000,
            getValue: function (fieldName) {
                let tab = p.getTab(this.jRow);
                return p.getElementModelValue(tab, this.jRow, fieldName)
            },
            getConstant: function (constantName) {
                let constant = p.#constants[constantName].filter(c => c.Code === this.jRow.data('pctpCode'));
                if (!constant.length) constant = p.#constants[constantName].filter(c => c.subCode1 !== undefined && c.subCode1 === this.jRow.data('pctpCode'));
                if (!constant.length) constant = p.#constants[constantName].filter(c => c.subCode2 !== undefined && c.subCode2 === this.jRow.data('pctpCode'));
                if (!constant.length) throw p.isValidData(this.jRow.data('pctpCode')) ? `Cannot find constant '${constantName}' of ${this.jRow.data('pctpCode')}` : `'${p.getBookingId(p.getActiveTabName(), this.jRow)}' might be missing from the main table of ${p.getActiveTabName().toUpperCase()}. Cannot modify this row`;
                return constant[0];
            },
            addDays: function (date, days) {
                let result = new Date(date);
                result.setDate(result.getDate() + days);
                return result;
            },
            getDateDiffInDays(date1, date2) {
                if (!p.isValidData(date1) || !p.isValidData(date2)) return 0;
                date1.setHours(0, 0, 0, 0);
                date2.setHours(0, 0, 0, 0);
                return Math.round((date1 - date2) / this.oneDayInMs);
            },
            _ClientSubStatus: function () {
                let ClientReceivedDate = this.getValue('ClientReceivedDate')
                return p.isValidData(ClientReceivedDate) ? 'SUBMITTED' : 'PENDING';
            },
            _ClientSubOverdue: function () {
                let DeliveryDateDTR = this.getValue('DeliveryDateDTR')
                let ClientReceivedDate = this.getValue('ClientReceivedDate')
                let WaivedDays = this.getValue('WaivedDays')
                return this.getDateDiffInDays(this.addDays(DeliveryDateDTR, Number(this.getConstant('CDC_DCD').DCD)), ClientReceivedDate) + Number(WaivedDays);
            },
            _ClientPenaltyCalc: function () {
                let _ClientSubOverdue = this._ClientSubOverdue();
                return _ClientSubOverdue < 0 ? _ClientSubOverdue * 200.00 : 0;
            },
            _PODStatusPayment: function () {
                let _OverdueDays = this._OverdueDays();
                if (_OverdueDays >= 0) {
                    return 'Ontime';
                } else if (_OverdueDays > -13 && _OverdueDays < 0) {
                    return 'Late';
                }
                return 'Lost';
            },
            _OverdueDays: function () {
                let ActualHCRecDate = this.getValue('ActualHCRecDate')
                let _PODSubmitDeadline = new Date(p.SQLDateFormater(this._PODSubmitDeadline()))
                let HolidayOrWeekend = this.getValue('HolidayOrWeekend')
                if (!p.isValidData(ActualHCRecDate) && p.isValidData(_PODSubmitDeadline)) {
                    let OverDueDaysNet = this.getDateDiffInDays(_PODSubmitDeadline, new Date());
                    OverDueDaysNet += Number(HolidayOrWeekend)
                    return OverDueDaysNet
                } else if (p.isValidData(ActualHCRecDate) && p.isValidData(_PODSubmitDeadline)) {
                    let OverDueDaysNet = this.getDateDiffInDays(_PODSubmitDeadline, ActualHCRecDate);
                    OverDueDaysNet += Number(HolidayOrWeekend)
                    return OverDueDaysNet
                }
                return 0;
            },
            _InteluckPenaltyCalc: function () {
                switch (this._PODStatusPayment()) {
                    case 'Ontime':
                        return 0;
                    case 'Late':
                        let OverdueDays = this._OverdueDays();
                        return OverdueDays < 0 ? OverdueDays * 200 : 0;
                    case 'Lost':
                        return 0;
                    default:
                        break;
                }
            },
            _LostPenaltyCalc: function () {
                let _PODStatusPayment = this._PODStatusPayment()
                let InitialHCRecDate = this.getValue('InitialHCRecDate')
                let DeliveryDateDTR = this.getValue('DeliveryDateDTR')
                if (!p.isValidData(InitialHCRecDate) && p.isValidData(DeliveryDateDTR)) {
                    if (_PODStatusPayment === 'Lost') {
                        return Number(this.getConstant('TotalInitialTruckers').TotalInitialTruckers) * 2;
                    }
                } else if (p.isValidData(InitialHCRecDate) && p.isValidData(DeliveryDateDTR)) {
                    if (_PODStatusPayment === 'Lost') {
                        return -Math.abs(Number(this.getConstant('TotalInitialTruckers').TotalInitialTruckers)) * 2;
                    }
                }
                return 0;
            },
            _TotalSubPenalties: function () {
                return this._ClientPenaltyCalc() + this._InteluckPenaltyCalc() + this._LostPenaltyCalc() + Number(this.getValue('PenaltiesManual'));
            },
            _TotalPenaltyWaived: function () {
                return Math.abs(this._TotalSubPenalties() - (this.getValue('PercPenaltyCharge') * this._TotalSubPenalties()));
            },
            _PODSubmitDeadline: function () {
                try {
                    let DeliveryDateDTR = this.getValue('DeliveryDateDTR');
                    if (!p.isValidData(DeliveryDateDTR)) return '';
                    DeliveryDateDTR.setDate(DeliveryDateDTR.getDate() + Number(this.getConstant('CDC_DCD').CDC));
                    return p.SAPDateFormater(p.getDateDefaultFormat(DeliveryDateDTR))
                } catch (error) {
                    p.log(error)
                    return '';
                }
            },
            _TotalInitialClient: function () {
                let _GrossClientRatesTax = this._GrossClientRatesTax();
                let _Demurrage4 = this._Demurrage4();
                let _AddtlCharges2 = this._AddtlCharges2();
                return _GrossClientRatesTax + _Demurrage4 + _AddtlCharges2;
            },
            _TotalInitialTruckers: function () {
                let _GrossTruckerRatesTax = this._GrossTruckerRatesTax();
                let _Demurrage3 = this._Demurrage3();
                let _AddtlCharges = this._AddtlCharges();
                return _GrossTruckerRatesTax + _Demurrage3 + _AddtlCharges;
            },
            _TotalGrossProfit: function () {
                return this._TotalInitialClient() - this._TotalInitialTruckers();
            },
            _GrossClientRatesTax: function () {
                let GrossClientRates = this.getValue('GrossClientRates');
                if (this.getConstant('TaxType').TaxTypeClient === 'Y') {
                    return GrossClientRates
                } else {
                    return GrossClientRates / 1.12
                }
            },
            _GrossTruckerRatesTax: function () {
                let GrossTruckerRates = this.getValue('GrossTruckerRates');
                if (this.getConstant('TaxType').TaxTypeTrucker === 'Y') {
                    return GrossTruckerRates
                } else {
                    return GrossTruckerRates / 1.12
                }
            },
            _Demurrage4: function () {
                let Demurrage = this.getValue('Demurrage');
                if (this.getConstant('TaxType').TaxTypeClient === 'Y') {
                    return Demurrage
                } else {
                    return Demurrage / 1.12
                }
            },
            _Demurrage3: function () {
                let Demurrage2 = this.getValue('Demurrage2');
                if (this.getConstant('TaxType').TaxTypeTrucker === 'Y') {
                    return Demurrage2
                } else {
                    return Demurrage2 / 1.12
                }
            },
            _TotalAddtlCharges: function () {
                let AddtlDrop = this.getValue('AddtlDrop');
                let BoomTruck = this.getValue('BoomTruck');
                let Manpower = this.getValue('Manpower');
                let Backload = this.getValue('Backload');
                return AddtlDrop + BoomTruck + Manpower + Backload;
            },
            _AddtlCharges2: function () {
                let _TotalAddtlCharges = this._TotalAddtlCharges();
                if (this.getConstant('TaxType').TaxTypeClient === 'Y') {
                    return _TotalAddtlCharges
                } else {
                    return _TotalAddtlCharges / 1.12
                }
            },
            _totalAddtlCharges2: function () {
                let AddtlDrop2 = this.getValue('AddtlDrop2');
                let BoomTruck2 = this.getValue('BoomTruck2');
                let Manpower2 = this.getValue('Manpower2');
                let Backload2 = this.getValue('Backload2');
                return AddtlDrop2 + BoomTruck2 + Manpower2 + Backload2;
            },
            _AddtlCharges: function () {
                let _totalAddtlCharges2 = this._totalAddtlCharges2();
                if (this.getConstant('TaxType').TaxTypeTrucker === 'Y') {
                    return _totalAddtlCharges2;
                } else {
                    return _totalAddtlCharges2 / 1.12;
                }
            },
            _GrossProfit: function () {
                let sumOfClientDemurrageTotalAddChargesBasedTaxType = Number(this._Demurrage4()) + Number(this._AddtlCharges2());
                let sumOfTruckerDemurrageTotalAddChargesBasedTaxType = Number(this._Demurrage3()) + Number(this._AddtlCharges());
                return sumOfClientDemurrageTotalAddChargesBasedTaxType - sumOfTruckerDemurrageTotalAddChargesBasedTaxType;
            },
            _GrossProfitNet: function () {
                let _GrossClientRatesTax = Number(this._GrossClientRatesTax());
                let _GrossTruckerRatesTax = Number(this._GrossTruckerRatesTax());
                return _GrossClientRatesTax - _GrossTruckerRatesTax;
            },
            _TotalRecClients: function () {
                let net = 0;
                net += Number(this.getValue('GrossInitialRate'));
                net += Number(this.getValue('Demurrage'));
                net += Number(this.getValue('AddCharges'));
                net += Number(this.getValue('ActualBilledRate'));
                net += Number(this.getValue('RateAdjustments'));
                net += Number(this.getValue('ActualDemurrage'));
                net += Number(this.getValue('ActualAddCharges'));
                return net;
            },
            _TotalPayable: function () {
                let net = 0;
                net += Number(this.getValue('GrossTruckerRatesN'));
                net += Number(this.getValue('DemurrageN'));
                net += Number(this.getValue('AddtlChargesN'));
                net += Number(this.getValue('ActualRates'));
                net += Number(this.getValue('RateAdjustments'));
                net += Number(this.getValue('ActualDemurrage'));
                net += Number(this.getValue('ActualCharges'));
                net += Number(this.getValue('BoomTruck2'));
                net += Number(this.getValue('OtherCharges'));
                net -= Number(this._TOTALDEDUCTIONS());
                return net;
            },
            _TOTALDEDUCTIONS: function () {
                let net = 0;
                net += Number(this.getValue('CAandDP'));
                net += Number(this.getValue('Interest'));
                net += Number(this.getValue('OtherDeductions'));
                net += Number(this.getValue('TotalPenalty'));
                return net;
            },
            _TotalPenalty: function () {
                return Math.abs(Math.abs(Number(this.getValue('TotalSubPenalty'))) - Math.abs(Number(this.getValue('TotalPenaltyWaived'))));
            },
            _VERIFICATION_TAT: function () {
                try {
                    let VerifiedDateHC = this.getValue('VerifiedDateHC');
                    if (!p.isValidData(VerifiedDateHC)) return 0;
                    let ActualHCRecDate = this.getValue('ActualHCRecDate');
                    return this.getDateDiffInDays(VerifiedDateHC, ActualHCRecDate);
                } catch (error) {
                    p.log(error)
                    return 0;
                }
            },
            _POD_TAT: function () {
                try {
                    let VerifiedDateHC = this.getValue('VerifiedDateHC');
                    if (!p.isValidData(VerifiedDateHC)) return 0;
                    let DeliveryDateDTR = this.getValue('DeliveryDateDTR');
                    return this.getDateDiffInDays(VerifiedDateHC, DeliveryDateDTR);
                } catch (error) {
                    p.log(error)
                    return '';
                }
            },
            _VarAR: function () {
                try {
                    let TotalAR = this.getValue('TotalAR');
                    let _TotalRecClients = this._TotalRecClients();
                    return TotalAR - _TotalRecClients;
                } catch (error) {
                    p.log(error)
                    return 0;
                }
            },
            _VarTP: function () {
                try {
                    let TotalAP = this.getValue('TotalAP');
                    let CAandDP = this.getValue('CAandDP');
                    let Interest = this.getValue('Interest');
                    let OtherDeductions = this.getValue('OtherDeductions');
                    let _TotalPayable = this._TotalPayable();
                    return TotalAP - (_TotalPayable + CAandDP + Interest);
                } catch (error) {
                    p.log(error)
                    return 0;
                }
            },
        };
    }
    log(...optionalParams) {
        if (this.#viewOptions.enable_test_logging || this.#viewOptions.enable_test_logging === undefined) console.log(...optionalParams);
    }

}

async function progressBar(count, fullCount, customText = '', withPresetText = true) {
    let progressBar = $('#progressBar');
    let progressText = $('#progressText');
    progressBar.css('width', (count / fullCount) * 100 + '%');
    if (withPresetText)
        progressText.html(customText + '  -  ADDING  ' + count + '  OUT OF  ' + fullCount);
    else
        progressText.html(customText + ' ' + Math.floor((count / fullCount) * 100) + '%');
}

function prepProgressBar() {
    remProgressBar();
    p.hidePortalMessage()
    $('#btnPost').attr('disabled', true);
    $('#btnBrowse').attr('disabled', true);
    $('#btnCancel').attr('disabled', true);
    $('#messageBar2').addClass('d-none');
    $('#progressDiv').removeClass('d-none');
}

function remProgressBar() {
    $('#btnBrowse').removeAttr('disabled');
    $('#btnCancel').removeAttr('disabled');
    $('#messageBar2').removeClass('d-none');
    $('#progressDiv').addClass('d-none');
}

function portalMessage(message, bgColor, textColor, timeoutms = 5000) {
    remProgressBar();
    $('#messageBar2').addClass('d-none');
    $('#messageBar3').removeClass('d-none');
    $('#messageBar').text(message).css({ 'background-color': bgColor, 'color': textColor });
    if (timeoutms > 0) setTimeout(() => p.hidePortalMessage(), timeoutms)
}

function promptMessage1Button(title, message, button1Label, info = '') {
    $('#promptTitle').html(title);
    $('#promptMessage').html(message);
    if (info !== '') {
        $('#promptInfo').html(info);
        $('#promptInfo').removeClass('d-none');
    }
    else {
        if (!$('#promptInfo').hasClass('d-none'))
            $('#promptInfo').addClass('d-none');
    }
    $('#btnPrompt1').removeClass('d-none');
    $('#btnPrompt1').html(button1Label);

    if (!$('#btnPrompt2').hasClass('d-none'))
        $('#btnPrompt2').addClass('d-none');

    $('#promptModal').modal('show');

    $('#btnPrompt1').off('click').click(function () {
        $('#promptModal').modal('hide');
        setTimeout(() => {
            $('#btnPrompt2').removeClass('d-none');
            $('#promptInfo').removeClass('d-none');
        }, 200);
    });
}

const p = new PctpWindowView();
setScreenLoading(true, false, '', true)