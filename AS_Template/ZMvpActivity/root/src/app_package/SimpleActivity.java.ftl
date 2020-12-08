package ${packageName}.ui;


<#if applicationPackage??>
import ${applicationPackage}.R;
</#if>
import android.os.Bundle;
import ${packageName}.contract.${contractInterface};
import ${packageName}.presenter.${presenter};
import ${corePackageName}.${baseActivity};


/**
 * Description :
 * @author : ${author}
 * @version : ${.now?string("yyyy-MM-dd hh:mm")} 1.0
 */
public class ${activityClass} extends ${baseActivity} implements ${contractInterface}.View {
    private ${contractInterface}.Presenter presenter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.${layoutName});
        presenter = new ${presenter}(this);
    }

}