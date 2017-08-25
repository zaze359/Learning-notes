package ${packageName}.ui;


<#if applicationPackage??>
import ${applicationPackage}.R;
</#if>
import android.os.Bundle;
import ${packageName}.view.${viewInterface};
import ${packageName}.presenter.${presenterInterface};
import ${packageName}.presenter.impl.${presenterImpl};
import ${corePackageName}.${baseActivity};


/**
 * Description :
 * @author : ${author}
 * @version : ${.now?string("yyyy-MM-dd hh:mm")} 1.0
 */
public class ${activityClass} extends BaseActivity implements ${viewInterface} {
    private ${presenterInterface} presenter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.${layoutName});
        presenter = new ${presenterImpl}(this);
    }

}