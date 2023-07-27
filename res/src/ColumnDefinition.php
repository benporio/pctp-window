<?php

require_once __DIR__.'/../inc/restriction.php';

class ColumnDefinition extends ASerializableClass
{
    public function __construct(
        public string $fieldName,
        public string $description,
        public ColumnType $columnType,
        public ColumnViewType $columnViewType = ColumnViewType::EDIT,
        public string $options = '',
        public bool $isGroupChange = false,
        public array $enableOnlyOptions = [],
    ){}
}