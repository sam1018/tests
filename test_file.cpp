VarDecl* var = nullptr;
auto varMatcher = varDecl(hasType(cxxRecordDecl(hasName("std::unordered_map"))
            .templateArgument(0,hasType(cxxRecordDecl(hasName("std::shared_ptr"))
            .templateArgument(0,hasType(constType())))),
            unless(hasAncestor(functionDecl(hasDescendant(functionTemplateSpecializationInfo(hasSpecializedTemplate(cxxRecordDecl(hasName("std::hash"))))))))),&var);
