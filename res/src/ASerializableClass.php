<?php

require_once __DIR__.'/../inc/restriction.php';

abstract class ASerializableClass
{
    function __serialize() {
        return array_map(fn($prop) => $this->{$prop->getName()}, (new ReflectionClass($this))->getProperties());
    }

    function __unserialize(array $data) {
        $props = (new ReflectionClass($this))->getProperties();
        for ($i=0; $i < count($data) ; $i++) { 
            $this->{$props[$i]->getName()} = $data[$i];
        }
    }
}