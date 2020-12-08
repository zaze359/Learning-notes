package ${packageName}

import android.<#if appCompat>support.v4.</#if>app.Fragment
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
<#if applicationPackage??>
import ${applicationPackage}.R
</#if>

/**
 * Description :
 * @author : ${author}
 * @version : ${.now?string("yyyy-MM-dd hh:mm")} 1.0
 */
open class ${fragmentClass} : Fragment() {

    constructor() : super()

    override fun onCreateView(inflater : LayoutInflater inflater, container : ViewGroup,
            savedInstanceState : Bundle) : View {
        return inflater.inflate(R.layout.${fragmentLayoutName}, container, false)
    }
}
