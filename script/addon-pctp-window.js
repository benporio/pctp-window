$(() => {

//===============INITIALIZATION===============//

    //Loading of tabs
    initialize((data, callback) => {
        renderHeader(data);
        p.initialize(data);
        p.reloadTab({tab: 'summary'});
        p.reloadTab({tab: 'pod'});
        p.reloadTab({tab: 'billing'});
        p.reloadTab({tab: 'tp'});
        p.reloadTab({tab: 'pricing'});
        p.reloadTab({tab: 'treasury'}, callback);
    });


//===============EVENTS===============//
    
    //Execution of controller's methods that are mapped to buttons using data-action attribute
    $('button[data-pctp-action]').on('click', async (e) => {
        const action = $(e.target).data('pctpAction');
        let sapDocToPost = '';
        switch (action) {
            case 'createArInvoice':
                sapDocToPost = 'AR_INVOICE';
                break;
            case 'createApInvoice':
                sapDocToPost = 'AP_INVOICE';
                break;
            default:
                break;
        }
        if (sapDocToPost) {
            const fieldOptions = p.sapDocumentStructures[sapDocToPost].fieldOptions
            if (fieldOptions.validation) {
                const selectedSapDataRows = p.selectedSapDataRows.filter(s => s.tab === p.getActiveTabName());
                let invalidLineCount = 0;
                for (const selectedSapDataRow of selectedSapDataRows) {
                    if (!(new RegExp(fieldOptions.validation.validRegex)).test(selectedSapDataRow.props[fieldOptions.validation.field])) {
                        invalidLineCount++;
                    }
                }
                if (invalidLineCount && invalidLineCount !== selectedSapDataRows.length) {
                    promptMessage1Button(
                        'Multiple Rates Error',
                        fieldOptions.validation.failedMessage,
                        'OK',
                    )
                    return false;
                } else if (invalidLineCount === selectedSapDataRows.length) {
                    await callAction(action, $(e.target).data('arg'))
                    return false;
                }
            }
            
            const message = `
                <div>
                    <p>${fieldOptions.caption}</p>
                    <div class="row">
                        ${
                            fieldOptions.options.map((opt, index) => {
                                return `
                                    <div class="col-6">
                                        <input type="${p.viewOptions.multiple_rates_selection.enabled ? 'checkbox' : 'radio'}" id="option${index}" name="${fieldOptions.sapField}" value="${opt.value}">
                                        <label for="option${index}">${opt.text}</label>
                                    </div>
                                `;
                            }).join('')
                        }
                    </div>
                </div>
            `;
            const callback = async (prop) => {
                p.sapDocumentStructures = await p.getApiData({doRefresh: true, prop: 'sapDocumentStructures'}).then(data => data).catch(console.log)
                p.log(JSON.parse(JSON.stringify(p.sapDocumentStructures)))
                if (prop.bool) {
                    p.log($(`input[type="radio"][name="${fieldOptions.sapField}"]:checked`).val())
                    let replacement = null;
                    if (p.viewOptions.multiple_rates_selection.enabled) {
                        replacement = fieldOptions.options.filter((opt, index) => $(`#option${index}`).is(':checked')).map(opt => opt.value);
                        p.log(replacement)
                        if (replacement.length === 1) replacement = replacement[0]
                    } else {
                        replacement = $(`input[type="radio"][name="${fieldOptions.sapField}"]:checked`).val()
                    }
                    for (const sapField in p.sapDocumentStructures[sapDocToPost][fieldOptions.part]) {
                        if (Object.hasOwnProperty.call(p.sapDocumentStructures[sapDocToPost][fieldOptions.part], sapField)) {
                            if (sapField === fieldOptions.sapField) {
                                const formerField = p.sapDocumentStructures[sapDocToPost][fieldOptions.part][sapField]
                                p.sapDocumentStructures[sapDocToPost].fieldValidations[formerField].enabled = false
                                p.sapDocumentStructures[sapDocToPost][fieldOptions.part][sapField] = replacement
                                break;
                            }
                        }
                    }
                    let hasFound = false;
                    for (const sapField in p.sapDocumentStructures[sapDocToPost].fieldValidations) {
                        if (Object.hasOwnProperty.call(p.sapDocumentStructures[sapDocToPost].fieldValidations, sapField)) {
                            const fieldValidation = p.sapDocumentStructures[sapDocToPost].fieldValidations[sapField]
                            for (const key in fieldValidation) {
                                if (Object.hasOwnProperty.call(fieldValidation, key)) {
                                    if (key === 'overrideLine') {
                                        const overrideLine = fieldValidation[key];
                                        for (const field in overrideLine) {
                                            if (Object.hasOwnProperty.call(overrideLine, field)) {
                                                if (field === fieldOptions.sapField) {
                                                    p.sapDocumentStructures[sapDocToPost].fieldValidations[sapField].overrideLine[field] = replacement
                                                    hasFound = true;
                                                    break;
                                                }
                                            }
                                        }
                                        if (hasFound) break;
                                    }
                                }
                            }
                            if (hasFound) break;
                        }
                    }
                    p.log(p.sapDocumentStructures[sapDocToPost])
                    await callAction(action, $(e.target).data('arg'))
                }
            }
            p.promptMessage2Buttons2ReturnBools({
                title: sapDocToPost + ' Creation', 
                message: message, 
                button1Label: 'Select', 
                button2Label: 'Cancel', 
                prop: {}, 
                info: '', 
                callback: callback, 
                isOutsideCallback: true
            })
        } else {
            await callAction(action, $(e.target).data('arg'))
        }
    })

    $('a.nav-link').on('click', async (e) => {
        $('.exceldownload').each(function() {
            if (!$(this).hasClass('d-none') && !$(this).find('.fa-file-excel').css('animation').includes('color-change')) $(this).addClass('d-none')
        })
        const tabName = e.currentTarget.id.replace('tab', '');
        if (p.hasDataTable(tabName)) $(`#${tabName}excel`).removeClass('d-none');
        p.renderCountTabUpdate(tabName)
        p.renderPostingButtons(tabName)
    })

    $('div.exceldownload').on('click', async (e) => {
        const tabName = p.getActiveTabName();
        const excelIcon = $(`#${tabName}excelicon`);
        if (p.tabSettings[tabName].hasExcelDownloadProcessing || excelIcon.css('animation').includes('color-change')) return false;
        setScreenLoading(true, false, `Creating ${tabName}-tab-excel.xlsx (${p.fetchTableRowsCount[tabName]} row${Number(p.fetchTableRowsCount[tabName]) > 1 ? 's' : ''}), please wait...`)
        p.downloadExcel(tabName, excelIcon).then(data => setScreenLoading(false, true))
    })

    $(document.body).on('click','#btncancel',function() {
        window.location.replace('../../dashboard/templates/dashboard.php')
    })
    $(document.body).on('click', '#btnLogout', function() {
        $('#logoutModal').modal('show');
    });
    $(document.body).on('click', '.pctpTabTable tbody tr', function(event) {
        if (p.viewOptions.control_key_row_selection && event.ctrlKey) {
            const checkbox = $(this).find('input[type=checkbox]');
            checkbox.prop('checked', !checkbox.is(':checked'))
            selectTableRow(checkbox)
            selectRow(checkbox)
        }
    });
    $(document.body).on('click', '#btnLogoutConfirm', function (){
        $('#logoutModal').modal('hide');
        $.ajax({
            type: 'GET',
            url: '../proc/views/utilities/vw_logout.php',
            success: function (html) 
            {
                window.location.reload();
            }
        }); 
    });
    $(document.body).on('change', '.dateInputVal', function() {
        let dateInputFaceElement = $(this).siblings();
        dateInputFaceElement.val(!p.isValidData($(this).val()) ? '' : p.SAPDateFormater($(this).val()));
    });
    $(document.body).on('change', '.dateInputFace', function() {
        let dateInputValElement = $(this).siblings();
        if ($(this).val() === '') {
            dateInputValElement.val('')
            if (dateInputValElement.data('pctpModel')) p.fieldOnchange(dateInputValElement)
            return false;
        }
        if ((new Date($(this).val())) == 'Invalid Date') {
            p.showError('Cannot parse date from the entered date format. Value has been refreshed')
            if (dateInputValElement.data('pctpValue') !== undefined && p.isValidData(dateInputValElement.data('pctpValue'))) {
                $(this).val(p.SAPDateFormater(dateInputValElement.data('pctpValue')));
            } else if (p.isValidData(dateInputValElement.val())) {
                $(this).val(p.SAPDateFormater(dateInputValElement.val()));
            } else {
                $(this).val('');
            }
        } else {
            $(this).val(p.SAPDateFormater(new Date($(this).val())));
            dateInputValElement.val(p.SQLDateFormater(new Date($(this).val())))
        }
        if (dateInputValElement.data('pctpModel')) p.fieldOnchange(dateInputValElement)
    });
    $(document.body).on('change', 'input[data-pctp-type="FLOAT"]', function() {
        $(this).val(p.formatAsMoney($(this).val()).replaceAll(',', ''))
    });
    $(document.body).on('change', 'input[data-pctp-type="TIME"]', function() {
        p.validateTime($(this))
    });
    $(document.body).on('change', '*[data-pctp-group-change]', function() {
        if (!p.getRow($(this)).hasClass('selected')) return false;
        setScreenLoading(true);
        const tab = p.getActiveTabName();
        const refValue = p.getAnonymousElementValue($(this))
        const field = $(this).data('pctpModel')
        if (p.isMainCheckboxChecked[tab]) p.groupChangeProps[tab][field] = refValue;
        $(`#tabtbl${tab}`).DataTable().$('tr.selected').each(function(){
            const targetElement = $(this).find(`[data-pctp-model="${field}"]`)
            const checkValue = p.getAnonymousElementValue(targetElement)
            if (checkValue !== refValue) {
                p.setAnonymousElementValue(tab, targetElement, refValue);
                p.fieldOnchange(targetElement);
            }
        })
        let newModifiedRows = [], modifiedRowCodes = [];
        const modifiedTabRows = p.modifiedRows.filter(m => m.tab === tab);
        if (modifiedTabRows.length) {
            for (const modifiedRow of modifiedTabRows[0].rows) {
                if (modifiedRow.props !== undefined && modifiedRow.props[field] !== undefined && modifiedRow.props[field] !== refValue) {
                    modifiedRow.props[field] = refValue;
                    newModifiedRows.push(modifiedRow)
                    modifiedRowCodes.push(modifiedRow.rowCode)
                }
            }
        }
        for (const selectedModifiedRowCode of p.selectedModifiedRows) {
            if (!modifiedRowCodes.includes(selectedModifiedRowCode)) {
                let props = {}, old = {}, otherProps = {};
                props[field] = refValue;
                let rowNum = p.rowNumCodePairs.filter(r => r.code === selectedModifiedRowCode)[0].rowNum
                if (modifiedTabRows.length && modifiedTabRows[0].rows.some(m => m.rowCode === selectedModifiedRowCode)) {
                    for (const modifiedRow of modifiedTabRows[0].rows) {
                        if (modifiedRow.rowCode === selectedModifiedRowCode) {
                            otherProps = {
                                ...modifiedRow
                            }
                            props = {
                                ...modifiedRow.props,
                                ...props,
                            }
                            old = {
                                ...modifiedRow.old,
                                ...old,
                            }
                            break;
                        }
                    }
                }
                newModifiedRows.push({
                    ...otherProps,
                    Code: selectedModifiedRowCode.replace(/[a-z]+/, ''),
                    rowCode: selectedModifiedRowCode,
                    rowNum: rowNum,
                    old: old,
                    tab: tab,
                    props: props
                })
            }
        }
        for (const modifiedRow of p.modifiedRows) {
            if (modifiedRow.tab === tab) {
                modifiedRow.rows = newModifiedRows;
                break;
            }
        }
        setScreenLoading(false, true);
    });

    $('#txtptfno').on('search', function () {
        $('#chkptfno').attr('disabled', false);
    });

    $('#chkbillingstatus').on('click', function () {
        if ($(this).is(':checked')) {
            $('#selbillingstatus').val('')
        }
    });

    $('#selbillingstatus').on('change', function () {
        if ($('#chkbillingstatus').is(':checked')) {
            $('#chkbillingstatus').prop('checked', false)
        }
    });
});