package ${packageName}.ui;

<#if applicationPackage??>
import ${applicationPackage}.R;
</#if>
import android.os.Bundle;
import ${packageName}.contract.${contractInterface};
import ${packageName}.presenter.${presenter};
import ${mvpPackageName}.${mvpActivity};

import kotlinx.android.synthetic.main.${layoutName}.*

/**
 * Description :
 * @author : ${author}
 * @version : ${.now?string("yyyy-MM-dd hh:mm")} 1.0
 */
open class ${activityClass} : ${mvpActivity}<${contractInterface}.View, ${contractInterface}.Presenter>(), ${contractInterface}.View {

    override fun isNeedHead() :Boolean {
        return true
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.${layoutName})
    }

    override fun getPresenter() : ${contractInterface}.Presenter {
        return ${presenter}(this)
    }

}