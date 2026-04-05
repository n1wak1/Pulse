package com.pulse.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

import java.util.Set;
import java.util.regex.Pattern;

public class RussianEmailValidator implements ConstraintValidator<RussianEmail, String> {

    private static final Pattern LOCAL_PART_PATTERN = Pattern.compile("^[A-Za-z0-9._%+-]+$");
    private static final Set<String> ALLOWED_DOMAINS = Set.of(
            "mail.ru",
            "inbox.ru",
            "list.ru",
            "bk.ru",
            "yandex.ru",
            "ya.ru",
            "rambler.ru"
    );

    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        if (value == null || value.isBlank()) {
            return true;
        }

        int atIndex = value.indexOf('@');
        if (atIndex <= 0 || atIndex != value.lastIndexOf('@') || atIndex == value.length() - 1) {
            return false;
        }

        String localPart = value.substring(0, atIndex);
        String domain = value.substring(atIndex + 1).toLowerCase();

        return LOCAL_PART_PATTERN.matcher(localPart).matches() && ALLOWED_DOMAINS.contains(domain);
    }
}
