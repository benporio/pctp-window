<?php

require_once __DIR__ . '/../inc/restriction.php';

class HybridHeader extends ASerializableClass
{
    public array $viewOptions = [];
    public ?object $sapDocumentStructures = null;
    public array $uploadedAttachment = [];
    public array $actionValidations = [];
    public array $columnValidations = [];
    public array $columnDefinitions = [];
    public array $dropDownOptions = [];
    public array $constants = [];
}
