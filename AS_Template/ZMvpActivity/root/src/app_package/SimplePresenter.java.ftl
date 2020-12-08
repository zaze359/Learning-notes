package ${packageName}.presenter;

import ${packageName}.contract.${contractInterface};
import ${mvpPackageName}.${basePresenterName};

/**
 * Description :
 * @author : ${author}
 * @version : ${.now?string("yyyy-MM-dd hh:mm")} 1.0
 */
public class ${presenter} extends ${basePresenterName}<${contractInterface}.View> implements ${contractInterface}.Presenter {
	
	public ${presenter}(${contractInterface}.View view) {
		super(view);
	}

}
