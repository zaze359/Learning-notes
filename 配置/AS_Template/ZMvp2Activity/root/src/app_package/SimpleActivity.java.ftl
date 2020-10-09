package ${packageName}.ui;

<#if applicationPackage??>
import ${applicationPackage}.R;
</#if>
import android.os.Bundle;
import ${packageName}.contract.${contractInterface};
import ${packageName}.presenter.${presenter};
import ${mvpPackageName}.${mvpActivity};


/**
 * Description :
 * @author : ${author}
 * @version : ${.now?string("yyyy-MM-dd hh:mm")} 1.0
 */
public class ${activityClass} extends ${mvpActivity}<${contractInterface}.View, ${contractInterface}.Presenter> implements ${contractInterface}.View {

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
    protected ${contractInterface}.Presenter getPresenter() {
        return new ${presenter}(this);
    }

}