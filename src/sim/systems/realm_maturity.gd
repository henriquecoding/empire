class_name RealmMaturity
extends RefCounted


static func missing(stage: RealmStageData, facts: Dictionary) -> StringName:
	for feat in stage.maturity:
		if not bool(facts.get(feat, false)):
			return feat
	return &""
