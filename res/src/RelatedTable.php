<?php

require_once __DIR__.'/../inc/restriction.php';

class RelatedTable extends ASerializableClass
{
    public function __construct(
        public string $tab,
        public string $ownField,
        public string $foreignField,
    ){}
}