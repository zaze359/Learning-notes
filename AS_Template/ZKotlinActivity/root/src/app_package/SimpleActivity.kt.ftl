package ${packageName}.ui


<#if applicationPackage??>
import ${applicationPackage}.R
</#if>
import android.os.Bundle
import ${packageName}.view.${viewInterface}
import ${packageName}.presenter.${presenterInterface}
import ${packageName}.presenter.impl.${presenterImpl}
import ${corePackageName}.${baseActivity}
import kotlinx.android.synthetic.main.${layoutName}.*

/**
 * Description :
 * @author : ${author}
 * @version : ${.now?string("yyyy-MM-dd hh:mm")} 1.0
 */
open class ${activityClass} : ${baseActivity}(), ${viewInterface} {
    var presenter : ${presenterInterface}? = null

    override fun onCreate(savedInstanceState : Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.${layoutName})
        presenter = ${presenterImpl}(this)
    }

}