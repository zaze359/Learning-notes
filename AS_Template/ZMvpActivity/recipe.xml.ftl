<?xml version="1.0"?>
<recipe>
   <!--  <#include "../common/recipe_manifest.xml.ftl" />

<#if generateLayout>
    <#include "../common/recipe_simple.xml.ftl" />
    <open file="${escapeXmlAttribute(resOut)}/layout/${layoutName}.xml" />
</#if> -->


    <merge from="root/AndroidManifest.xml.ftl"
             to="${escapeXmlAttribute(manifestOut)}/AndroidManifest.xml" />

    <instantiate from="root/src/app_package/SimpleActivity.java.ftl"
                    to="${escapeXmlAttribute(srcOut)}/ui/${activityClass}.java" />

	<instantiate from="root/src/app_package/SimpleContract.java.ftl"
                    to="${escapeXmlAttribute(srcOut)}/contract/${contractInterface}.java" />

	<instantiate from="root/src/app_package/SimplePresenter.java.ftl" 
 					to="${escapeXmlAttribute(srcOut)}/presenter/${presenter}.java" />

    <instantiate from="root/res/layout/SimpleLayout.xml.ftl"
                 to="${escapeXmlAttribute(resOut)}/layout/${layoutName}.xml" /> 
                 
    <!-- <open file="${escapeXmlAttribute(srcOut)}/ui/${activityClass}.java" /> -->
                    
</recipe>
