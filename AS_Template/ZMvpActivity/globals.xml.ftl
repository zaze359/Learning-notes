<?xml version="1.0"?>
<globals>
    <global id="hasNoActionBar" type="boolean" value="false" />
    <global id="parentActivityClass" value="" />
    <global id="simpleLayoutName" value="${layoutName}" />
    <global id="excludeMenu" type="boolean" value="true" />
    <global id="generateActivityTitle" type="boolean" value="false" />
    <#include "../common/common_globals.xml.ftl" />

    <global id="author" value="zaze" />
    <!-- base -->
	<global id="corePackageName" type="string" value="com.zaze.common.base" />
    <global id="basePresenterName" type="string" value="BasePresenter" />
    <global id="baseViewName" type="string" value="BaseView" />
    <!-- mvp -->
    <global id="mvpPackageName" type="string" value="com.zaze.common.base.mvp" />
	<global id="mvpPresenterName" type="string" value="BaseMvpPresenter" />
    <global id="mvpActivity" type="string" value="BaseMvpActivity" />
    <global id="mvpFragment" type="string" value="BaseMvpFragment" />

</globals>
