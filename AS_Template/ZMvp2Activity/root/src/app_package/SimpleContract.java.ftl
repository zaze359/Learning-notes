package ${packageName}.contract;

import ${corePackageName}.${baseViewName};
import ${corePackageName}.${basePresenterName};

/**
 * Description : 
 * @author : ${author}
 * @version : ${.now?string("yyyy-MM-dd hh:mm")} 1.0
 */
public interface ${contractInterface} {

	interface View extends ${baseViewName} {

	}

	interface Presenter extends ${basePresenterName}<View> {
		
	}

}
