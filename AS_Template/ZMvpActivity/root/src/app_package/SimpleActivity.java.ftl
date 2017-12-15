package ${packageName}.ui;

<#if applicationPackage??>
import ${applicationPackage}.R;
</#if>
import android.os.Bundle;
import ${packageName}.view.${viewInterface};
import ${packageName}.presenter.${presenterInterface};
import ${packageName}.presenter.impl.${presenterImpl};
import ${mvpPackageName}.${mvpActivity};


/**
 * Description :
 * @author : ${author}
 * @version : ${.now?string("yyyy-MM-dd hh:mm")} 1.0
 */
public class ${activityClass} extends ${mvpActivity}<${viewInterface}, ${presenterInterface}> implements ${viewInterface} {

	@Override
    protected boolean isNeedHead() {
        return true;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.${layoutName});
    }

    @Override
    protected ${presenterInterface} getPresenter() {
        return new ${presenterImpl}(this);
    }

}