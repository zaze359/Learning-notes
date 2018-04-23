package ${packageName}.presenter.impl;

import ${packageName}.presenter.${presenterInterface};
import ${packageName}.view.${viewInterface};
import ${mvpPackageName}.${mvpPresenterName};

/**
 * Description :
 * @author : ${author}
 * @version : ${.now?string("yyyy-MM-dd hh:mm")} 1.0
 */
public class ${presenterImpl} extends ${mvpPresenterName}<${viewInterface}> implements ${presenterInterface} {
	public ${presenterImpl}(${viewInterface} view) {
        super(view);
    }
}
