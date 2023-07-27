<?php

require_once __DIR__.'/../inc/restriction.php';

abstract class ASAPDocumentStructure extends ASerializableClass
{
    public function __construct(
        public SAPDocumentStructureType $objectType,
        public array $headers,
        public array $lines,
        public array $defaults,
        public array $columnTypes,
        public array $fieldValidations = [],
        public array $fieldOptions = [],
        public array $fieldPreProcessing = [],
    ){}

    public function getColumnType(string $key): ?ColumnType {
        if (array_key_exists($key, $this->columnTypes)) {
            return $this->columnTypes[$key];
        }
        return null;
    }
}