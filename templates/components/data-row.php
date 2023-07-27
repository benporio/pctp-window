<?php
$modelTab = $model->{$tabKeyword . 'Tab'};
$settings = $modelTab->settings;
$formula = '';
if (preg_match('/^_\S+$/', $columnDefinition->fieldName)) {
    $formula = 'data-pctp-formula="' . $columnDefinition->fieldName . '"';
}
$fieldName = preg_replace('/^_/', '', $columnDefinition->fieldName);
$events = '';
if (isset($model->getColumnValidations()[$tabKeyword][$fieldName])) {
    foreach ($model->getColumnValidations()[$tabKeyword][$fieldName]->events as $eventType => $eventOptions) {
        $events .= ' ' . $eventType . '="fieldEvent($(this), \'' . $eventType . '\')" ';
    }
}
$constant = '';
if (isset($modelTab->fieldEnumValues) && (bool)((array)$modelTab->fieldEnumValues)) {
    if (in_array($columnDefinition->fieldName, $modelTab->fieldEnumValues->fields)) {
        $enum = $modelTab->fieldEnumValues->enum;
        $constant = 'data-pctp-check="' . $enum . '"';
    }
}
$cascade = '';
switch ($columnDefinition->fieldName) {
    case 'SAPClient':
        $cascade = 'data-pctp-cascade="ClientName,GroupProject"';
        break;
    case 'SAPTrucker':
        $cascade = 'data-pctp-cascade="TruckerName"';
        break;
    default:
        # code...
        break;
}
$groupChange = '';
if ($columnDefinition->isGroupChange) {
    $groupChange = 'data-pctp-group-change';
}
$exclude = '';
if ((bool)$modelTab->foreignFields && in_array($columnDefinition->fieldName, $modelTab->foreignFields)) {
    $exclude = 'data-pctp-update-exclude';
}

$additionalDataAtttributes = join(' ', [
    $formula,
    $events,
    $constant,
    $cascade,
    $groupChange,
    $exclude,
]);
?>
<?php if ($fieldName === 'Attachment') : ?>
    <a data-pctp-type="<?= $columnDefinition->columnType->value ?>" <?= $additionalDataAtttributes ?> data-pctp-model="<?= $fieldName ?>" data-pctp-value="<?= $tableRow->{$fieldName} ?>" onclick="clickAttachmentLink(this, event)" href="" title="<?= (bool)$tableRow->{$fieldName} ? $tableRow->{$fieldName} : '' ?>">
        <?= (bool)$tableRow->{$fieldName} ? '1 attachment' : 'No attachment' ?>
    </a>
<?php elseif ((isset($tableRow->DisableTableRow) && $tableRow->DisableTableRow === 'Y')
    || $model->user->{$tabKeyword . 'Access'} === TabAccessType::VIEW
    || (isset($tableRow->DisableSomeFields) && $tableRow->DisableSomeFields !== '' && ((bool)$modelTab->disableSomeFields)
        && isset($modelTab->disableSomeFields[$tableRow->DisableSomeFields]) && in_array($fieldName, $modelTab->disableSomeFields[$tableRow->DisableSomeFields]))
    || (isset($tableRow->DisableSomeFields2) && $tableRow->DisableSomeFields2 !== '' && ((bool)$modelTab->disableSomeFields)
        && isset($modelTab->disableSomeFields[$tableRow->DisableSomeFields2]) && in_array($fieldName, $modelTab->disableSomeFields[$tableRow->DisableSomeFields2]))
) : ?>
    <?php $value = $fieldName && !is_null($tableRow->{$fieldName}) ? $tableRow->{$fieldName} : ''; ?>
    <?php switch ($columnDefinition->columnType):
        case ColumnType::DATE: ?>
            <span <?= $additionalDataAtttributes ?> data-pctp-type="<?= $columnDefinition->columnType->value ?>" data-pctp-model="<?= $fieldName ?>" data-pctp-value="<?= PctpWindowTabHelper::getInstance($settings)->SQLDateFormatter($value) ?>"><?= $value ?></span>
            <?php break ?>
        <?php
        default: ?>
            <span <?= $additionalDataAtttributes ?> data-pctp-type="<?= $columnDefinition->columnType->value ?>" <?= $columnDefinition->columnType === ColumnType::FLOAT ? 'class="floatValue"' : '' ?> data-pctp-model="<?= $fieldName ?>" data-pctp-value="<?= $value ?>">
                <?= $value ?>
            </span>
    <?php endswitch ?>
<?php else : ?>
    <?php $placeHolder = 'No data' ?>
    <?php $inputHeight = '30px' ?>
    <?php switch ($columnDefinition->columnViewType):
        case ColumnViewType::AUTO:
            $value = $fieldName && !is_null($tableRow->{$fieldName}) ? $tableRow->{$fieldName} : '';
            if ($columnDefinition->columnType === ColumnType::FLOAT && is_null($tableRow->{$fieldName})) {
                $value = number_format(0, $settings->constants['SAPPriceDecimal']);
            }
    ?>
            <?php switch ($columnDefinition->columnType):
                case ColumnType::DATE: ?>
                    <span <?= $additionalDataAtttributes ?> data-pctp-type="<?= $columnDefinition->columnType->value ?>" data-pctp-model="<?= $fieldName ?>" data-pctp-value="<?= PctpWindowTabHelper::getInstance($settings)->SQLDateFormatter($value) ?>"><?= $value ?></span>
                    <?php break ?>
                <?php
                default: ?>
                    <span <?= $additionalDataAtttributes ?> <?= $events ? 'data-pctp-observer' : '' ?> data-pctp-type="<?= $columnDefinition->columnType->value ?>" <?= $columnDefinition->columnType === ColumnType::FLOAT ? 'class="floatValue"' : '' ?> data-pctp-model="<?= $fieldName ?>" data-pctp-value="<?= $value ?>">
                        <?= $value ?>
                    </span>
            <?php endswitch ?>
            <?php break ?>
        <?php
        case ColumnViewType::DROPDOWN: ?>
            <select <?= $additionalDataAtttributes ?> data-pctp-type="<?= $columnDefinition->columnType->value ?>" <?= $events ? 'data-pctp-observer' : '' ?> <?= !str_contains($events, 'onchange') ? 'onchange="fieldOnchange($(this))"' : '' ?> data-pctp-model="<?= $fieldName ?>" data-pctp-value="<?= $tableRow->{$fieldName} ?>" class="edit-field" id="sel<?= strtolower($fieldName) ?>" style="height: <?= $inputHeight ?>; width: 100%;" data-pctp-options="<?= $columnDefinition->options ?>">
                <?php
                $options = $model->dropDownOptions[$columnDefinition->options];
                $data = $tableRow->{$fieldName};
                ?>
                <?php if ((bool)$data && $data !== 'null') : ?>
                    <option value=""></option>
                    <?php if (!(bool)array_filter($options, fn ($z) => $z->Name === $data || $z->Code === $data)) : ?>
                        <option value="<?= $data ?>" selected><?= $data ?></option>
                    <?php endif ?>
                <?php else : ?>
                    <option value="" style="display: none;" disabled selected>Select...</option>
                    <option value=""></option>
                <?php endif ?>
                <?php foreach ($options as $option) : ?>
                    <?php
                    $hidden = '';
                    if (isset($columnDefinition->enableOnlyOptions) && (bool)$columnDefinition->enableOnlyOptions) {
                        $hidden = !in_array($option->Code, $columnDefinition->enableOnlyOptions) ? 'hidden' : '';
                    }
                    ?>
                    <option <?= $hidden ?> value="<?= $option->Code ?>" <?= $option->Name === $data || $option->Code === $data ? 'selected' : '' ?>><?= $option->Name ?></option>
                <?php endforeach ?>
            </select>
            <?php break ?>
        <?php
        default: ?>
            <?php
            $inputType;
            $inputValue = '';
            $inputPlaceholder = '';
            $alignment;
            switch ($columnDefinition->columnType) {
                case ColumnType::DATE:
                    $inputType = 'date';
                    if ((bool)$tableRow->{$fieldName}) {
                        $inputValue = PctpWindowTabHelper::getInstance($settings)->SQLDateFormatter($tableRow->{$fieldName});
                    } else {
                        $inputValue = '';
                    }
                    $alignment = 'center'; ?>
                    <div style="height: <?= $inputHeight ?>; vertical-align: middle;" class="col-12 input-group m-0 p-0">
                        <input type="text" class="col dateInputFace" style="text-align: <?= $alignment ?>; box-sizing: border-box;" 
                            value="<?= (bool)$tableRow->{$fieldName} ? $tableRow->{$fieldName} : '' ?>">
                        <input <?= $additionalDataAtttributes ?> <?= $events ? 'data-pctp-observer' : '' ?> 
                            <?= !str_contains($events, 'onchange') ? 'onchange="fieldOnchange($(this))"' : '' ?> 
                            data-pctp-model="<?= $fieldName ?>" data-pctp-value="<?= $inputValue ? $inputValue : '' ?>" 
                            class="edit-field dateInputVal" style="width: 30px; box-sizing: border-box;" 
                            type="<?= $inputType ?>" value="<?= $inputValue ? $inputValue : '' ?>" 
                            data-pctp-row-parent-distance="3"
                        >
                    </div>
            <?php break;
                case ColumnType::INT:
                case ColumnType::FLOAT:
                    $inputType = 'number';
                    $alignment = 'right';
                    if ($fieldName) {
                        if (!(bool)$tableRow->{$fieldName} && $tableRow->{$fieldName} !== 0) {
                            $inputPlaceholder = false;
                            $inputValue = number_format(0, $settings->constants['SAPPriceDecimal']);
                        } else {
                            $inputValue = str_replace(',', '', $tableRow->{$fieldName});
                        }
                    } else {
                        $inputPlaceholder = $placeHolder;
                    }
                    break;
                case ColumnType::TIME:
                    $inputType = 'text';
                    $alignment = 'left';
                    if ($fieldName) {
                        if (!(bool)$tableRow->{$fieldName}) {
                            $inputPlaceholder = $placeHolder;
                        } else {
                            $inputValue = $tableRow->{$fieldName};
                        }
                    } else {
                        $inputPlaceholder = $placeHolder;
                    }
                    break;
                default:
                    $inputType = 'text';
                    $alignment = 'left';
                    if ($fieldName) {
                        if (!(bool)$tableRow->{$fieldName}) {
                            $inputPlaceholder = $placeHolder;
                        } else {
                            $inputValue = $tableRow->{$fieldName};
                        }
                    } else {
                        $inputPlaceholder = $placeHolder;
                    }
                    break;
            }
            ?>
            <?php if ($columnDefinition->columnType !== ColumnType::DATE) : ?>
                <input <?= $additionalDataAtttributes ?> 
                    data-pctp-type="<?= $columnDefinition->columnType->value ?>" 
                    <?= $events ? 'data-pctp-observer' : '' ?> 
                    <?= !str_contains($events, 'onchange') ? 'onchange="fieldOnchange($(this))"' : '' ?> 
                    data-pctp-model="<?= $fieldName ?>" data-pctp-value="<?= $inputValue || $inputValue == 0 ? $inputValue : '' ?>" 
                    class="edit-field" style="height: <?= $inputHeight ?>; width: 100%; box-sizing: border-box; text-align: <?= $alignment ?>;" 
                    type="<?= $inputType ?>" value="<?= $inputValue || $inputValue == 0 ? $inputValue : '' ?>" 
                    <?= $inputPlaceholder ? 'placeholder="' . $inputPlaceholder . '"' : '' ?>
                >
            <?php endif ?>
            <?php break ?>
    <?php endswitch ?>
<?php endif ?>