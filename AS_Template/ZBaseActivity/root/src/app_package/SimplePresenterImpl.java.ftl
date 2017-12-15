package ${packageName}.presenter.impl;

import ${packageName}.presenter.${presenterInterface};
import ${mvpPackageName}.${basePresenterName};
import ${packageName}.view.${viewInterface};

/**
 * Description :
 * @author : ${author}
 * @version : ${.now?string("yyyy-MM-dd hh:mm")} 1.0
 */
public class ${presenterImpl} extends ${basePresenterName}<${viewInterface}> implements ${presenterInterface} {
	
	public ${presenterImpl}(${viewInterface} view) {
		super(view);
	}

}
