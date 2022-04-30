<?php

/**
 * @param array $useArray1
 * @param array $useArray2
 *
 * @return  array
 */
function mergeArrays(array $useArray1, array $useArray2): array
{
    $combined = $useArray1;

    foreach ($useArray2 as $key => $value) {

        if (is_array($value)) {
            if ( ! array_key_exists($key, $useArray1)) {
                $useArray1[ $key ] = [];
            }

            $combined[ $key ] = mergeArrays($useArray1[ $key ], $value);
        } else {
            if (array_key_exists($key, $useArray1) && is_array($useArray1[ $key ]) && count($useArray1[ $key ])) {
                $combined[ $key ][] = $value;
            } else {
                $combined[ $key ] = $value;
            }
        }
    }
    return $combined;
}

/**
 * @param array       $config
 * @param DOMDocument $document
 * @param DOMNode     $node
 */
function arrayToXml(array $config, DOMDocument $document, DOMNode $node)
{
    if (array_key_exists('@attributes', $config)) {
        foreach ($config[ '@attributes' ] as $attributeName => $attributeValue) {
            $attribute = $document->createAttribute($attributeName);
            $attribute->value = $attributeValue;
            $node->appendChild($attribute);
        }
        unset($config[ '@attributes' ]);
        if (count($config) > 1) {
            arrayToXml($config, $document, $node);
        } else {
            $values = array_values($config);
            $node->appendChild($document->createCDATASection(reset($values)));
        }
    } else {
        foreach ($config as $key => $value) {
            if (is_array($value)) {
                $subNode = $node->appendChild($document->createElement($key));
                arrayToXml($value, $document, $subNode);
            } else {
                $valueNode = $document->createElement($key);
                $valueNode->appendChild($document->createCDATASection($value));
                $node->appendChild($valueNode);
            }
        }
    }
}

/**
 * @param array $config
 *
 * @return string
 */
function prepareXML(array $config): string
{
    $document = new DOMDocument("1.0");
    $document->preserveWhiteSpace = false;
    $document->formatOutput = true;
    $rootNode = $document->appendChild($document->createElement('config'));
    arrayToXml($config, $document, $rootNode);
    return $document->saveXML();
}

if ( ! isset($argv[ 1 ])) {
    echo "Please specify a Magento configuration directory!\n";
    die(1);
}

$path = rtrim($argv[ 1 ], '/');

$magento1ConfigFile = sprintf('%s/local.xml', $path);

if (file_exists($magento1ConfigFile) && is_writable($magento1ConfigFile)) {
    $files = preg_grep('/local\.[\w_-]+\.xml$/', scandir($path));

    echo sprintf("Found %d configuration file(s)\n", count($files));

    if (count($files)) {
        $baseXml = simplexml_load_file(sprintf('%s/local.xml', $path));
        $configWithAttributes = json_decode(json_encode($baseXml), true);

        $baseXml = simplexml_load_file(sprintf('%s/local.xml', $path), 'SimpleXMLElement', LIBXML_NOCDATA);
        $configWithoutAttributes = json_decode(json_encode($baseXml), true);

        $config = mergeArrays($configWithAttributes, $configWithoutAttributes);

        foreach ($files as $file) {
            echo sprintf("Merge configuration file: %s\n", $file);

            $fileXml = simplexml_load_file(sprintf('%s/%s', $path, $file));
            $fileDataWithAttributes = json_decode(json_encode($fileXml), true);

            $fileXml = simplexml_load_file(sprintf('%s/%s', $path, $file), 'SimpleXMLElement', LIBXML_NOCDATA);
            $fileDataWithoutAttributes = json_decode(json_encode($fileXml), true);

            $config = mergeArrays($config, mergeArrays($fileDataWithAttributes, $fileDataWithoutAttributes));

            unlink(sprintf('%s/%s', $path, $file));
        }

        echo sprintf("Writing merged configuration to file: %s\n", $magento1ConfigFile);

        file_put_contents($magento1ConfigFile, prepareXML($config));
    } else {
        echo "Nothing to merge\n";
    }
} else {
    echo "Configuration file: %s not found or not writeable!";
    die(1);
}
