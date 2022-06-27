-- 1. Receba o ID de uma pessoa e o novo nome a ser alterado. Efetue a alteração ou
-- emita uma mensagem de erro caso ID inválido.
CREATE OR REPLACE FUNCTION altera_nome
(pessoa_id int, novo_nome character varying)
RETURNS integer AS
$$
BEGIN
	if (SELECT id FROM Pessoa WHERE id = pessoa_id) > 0 THEN
        UPDATE Pessoa 
        SET nome = novo_nome
        WHERE id = pessoa_id;
        RAISE NOTICE 'Nome alterado';
	RETURN 0;
    ELSE
        RAISE 'ID inválido';
	RETURN -1;
    END IF;     
END;
$$
LANGUAGE plpgsql;

SELECT altera_nome(2, 'Joana Dias');
SELECT altera_nome(1000,'Ana Pinheiro');
SELECT altera_nome(6, 'Heitor Freitas');

-- 2. Retorne uma tabela com todos os medicamentos cadastrados.
CREATE OR REPLACE FUNCTION medicamento_cadastrados()
RETURNS TABLE(id int, nome varchar(60))
AS
$$
	SELECT id, nome FROM medicamento;
$$
LANGUAGE SQL;

select * from medicamento_cadastrados();
select nome from medicamento_cadastrados();
select id from medicamento_cadastrados();
SELECT id, pessoa.nome,cidade.nome FROM Pessoa JOIN Cidade ON Pessoa.cidade_codigo = Cidade.codigo;
-- 3. Receba o nome completo de uma cidade e retorne uma tabela com ID e nome de
-- todas as pessoas que nela residem. Retorne um erro caso a cidade informada não
-- existir. 
CREATE OR REPLACE FUNCTION cidade_moradores(nome_cidade varchar(60))
RETURNS TABLE(id int, nome_pessoa varchar(60))
AS
$$
BEGIN
	if(SELECT count(*) FROM Cidade WHERE cidade.nome = nome_cidade) > 0 THEN
		RETURN QUERY 
			SELECT pessoa.id, pessoa.nome FROM Pessoa 
			JOIN Cidade ON Pessoa.cidade_codigo = Cidade.codigo 
			WHERE cidade.nome = nome_cidade;
	ELSE
        RAISE 'Cidade não existe';
    END IF;
END;
$$
LANGUAGE plpgsql;
SELECT cidade_moradores('Três Lagoas');
SELECT cidade_moradores('Presidente Prudente');
SELECT cidade_moradores('Corumbá');

-- 4. Receba o nome de um funcionário e retorne uma tabela com o nome de seus
-- dependentes, o grau de parentesco e o nome das cidades que eles moram.
CREATE OR REPLACE FUNCTION funcionarios_dependentes(nome_funcionario varchar(60))
RETURNS TABLE(nome_dep varchar(60), grau_parentesco char(1), nome_cidade varchar(60))
AS
$$
BEGIN
	if(SELECT count(*) FROM Pessoa JOIN Funcionario ON Funcionario.pessoa_id = Pessoa.id WHERE pessoa.nome = nome_funcionario) > 0 THEN
		RETURN QUERY 
			SELECT p_dependente.nome nome_dependente, dep.grau_parentesco, cidade.nome FROM Funcionario 
			JOIN Pessoa p_func ON Funcionario.pessoa_id = p_func.id
			JOIN Dependente dep ON dep.funcionario_id = Funcionario.pessoa_id 
			JOIN Pessoa p_dependente ON dep.pessoa_id = p_dependente.id
			JOIN Cidade ON p_dependente.cidade_codigo = Cidade.codigo
			WHERE p_func.nome = nome_funcionario;
	ELSE
        RAISE 'Funcionário não existe';
    END IF;
END;
$$
LANGUAGE plpgsql;
SELECT funcionarios_dependentes('Joana Dias');
SELECT funcionarios_dependentes('Gabriela');
SELECT funcionarios_dependentes('Gabriel Leituga');
-- 5. Receba um percentual de reajuste e aplique-o a todos os salários dos funcionários.
-- Você deve criar e povoar uma tabela temporária com o nome dos funcionários,
-- suas matrículas e seus salários antes e depois da aplicação do reajuste. Retorne
-- todos os registros da tabela temporária, ordenados alfabeticamente;
CREATE OR REPLACE FUNCTION reajuste(valor_percentual numeric(3,2))
RETURNS TABLE(nome_func varchar(60), matricula_func varchar(10), salario_ant numeric(6,2), salario_atual numeric(6,2))
AS
$$
BEGIN
	if(SELECT count(*) FROM Pessoa JOIN Funcionario ON Funcionario.pessoa_id = Pessoa.id) > 0 THEN
		RETURN QUERY 
			SELECT p_func.nome, funcionario.matricula, funcionario.salario_base, (funcionario.salario_base+((valor_percentual)*funcionario.salario_base)/100) FROM Funcionario 
			JOIN Pessoa p_func ON Funcionario.pessoa_id = p_func.id
			ORDER BY p_func.nome ASC;
			
    END IF;
END;
$$
LANGUAGE plpgsql;
SELECT reajuste(25);
SELECT reajuste(10);
SELECT reajuste(5.5);
-- 6. Retorne uma tabela com a lista ordenada dos médicos e suas especialidades:
-- nome do médico, código da especialidade, nome da especialidade, data do título e
-- descrição da especialidade; Sugestão de teste: Utilize a função para filtrar apenas
-- os cardiologistas;
CREATE OR REPLACE FUNCTION medicos_especialidades()
RETURNS TABLE(nome_medico varchar(60), codigo_especialidade varchar(12), nome_especialidade varchar(60), data_titulo date, descricao varchar(512))
AS
$$
BEGIN
	if(SELECT count(*) FROM Medico_especialidade) > 0 THEN
		RETURN QUERY 
			SELECT med.nome medico, especialidade.codigo codigo_especialidade, especialidade.nome especialidade, medico_especialidade.data_titulo, especialidade.descricao
			FROM medico_especialidade
			JOIN medico ON medico.id = medico_id
			JOIN pessoa med ON pessoa_id = med.id
			JOIN especialidade_medica especialidade ON especialidade.codigo = medico_especialidade.codigo_especialidade
			ORDER BY med.nome ASC;
    END IF;
END;
$$
LANGUAGE plpgsql;
SELECT * FROM medicos_especialidades();
SELECT * FROM medicos_especialidades() WHERE nome_especialidade = 'Cardiologia';
SELECT nome_especialidade, count(*) total_profissionais FROM medicos_especialidades() GROUP BY nome_especialidade ORDER BY total_profissionais ASC;
-- 7. Receba o nome completo de uma pessoa e retorne uma tabela com a lista dos
-- medicamentos para ela prescritos: data/hora do atendimento, nome do médico,
-- CRM, especialidade médica, nome do medicamento, apresentação, dosagem,
-- frequência e duração do tratamento;
CREATE OR REPLACE FUNCTION prescricao(nome_paciente varchar(60))
RETURNS TABLE(data_atendimento timestamp, nome_medico varchar(60), crm varchar(10), especialidade varchar(60), medicamento varchar(50), apresentacao varchar(35), dosagem varchar(20), frequencia varchar(20), duracao varchar(15))
AS
$$
BEGIN
	if(SELECT count(*) FROM Atendimento_medico JOIN Pessoa ON Pessoa.id = Atendimento_medico.paciente_id WHERE Pessoa.nome = nome_paciente) > 0 THEN
		RETURN QUERY 
			SELECT atendimento.data_hora, p_med.nome, medico.crm, especialidade_medica.nome, medicamento.nome, apresentacao_medicamento.nome, presc.dosagem, presc.frequencia, presc.duracao 
			FROM prescricao presc
			JOIN atendimento_medico atendimento ON atendimento.id = presc.atendimento_id
			JOIN medico_especialidade ON medico_especialidade.medico_id = atendimento.medico_id
			JOIN medico ON medico.id = medico_especialidade.medico_id
			JOIN pessoa p_med ON p_med.id = medico.id
			JOIN especialidade_medica ON especialidade_medica.codigo = medico_especialidade.codigo_especialidade 
			JOIN medicamento ON medicamento.id = presc.medicamento_id
			JOIN apresentacao_medicamento ON apresentacao_medicamento.id = presc.apresentacao_id
			JOIN pessoa p_paciente ON p_paciente.id = atendimento.paciente_id
			WHERE p_paciente.nome = nome_paciente;

	ELSE
        RAISE 'Paciente não existe';		
    END IF;
END;
$$
LANGUAGE plpgsql;
SELECT data_atendimento, nome_medico, medicamento FROM prescricao('Matheus Camargo');
SELECT * FROM prescricao('Pedro Meireles');
SELECT * FROM prescricao('Alice Souza');
-- 8. Receba o nome completo de uma pessoa. SE ela não for um funcionário apresente
-- uma mensagem de erro. Receba também o nome e o sexo de outra pessoa.
-- Cadastre essa segunda pessoa como dependente (filho(a)) da primeira e
-- mantenha o mesmo tipo de plano e a mesma cidade da primeira. Após o cadastro,
-- retorne a quantidade de dependentes da primeira pessoa.
CREATE OR REPLACE FUNCTION inserir_dep(nome_func varchar(60), nome_dep varchar(60), sexo_dep char(1))
RETURNS integer AS
$$
DECLARE tplano SMALLINT;
DECLARE id_func INT;
DECLARE id_dep INT;
DECLARE total_dep INT;
BEGIN
	if(SELECT count(*) FROM Funcionario JOIN Pessoa ON Pessoa.id = Funcionario.pessoa_id WHERE Pessoa.nome = nome_func) > 0 THEN
		
		SELECT p_func.tipo_plano_id INTO tplano FROM Funcionario 
		JOIN Pessoa p_func ON p_func.id = Funcionario.pessoa_id 
		WHERE p_func.nome = nome_func;
		INSERT INTO Pessoa(nome,sexo,tipo_plano_id)
			VALUES(nome_dep,sexo_dep,tplano);

		SELECT p_func.id INTO id_func FROM dependente
		JOIN funcionario ON funcionario.pessoa_id = dependente.funcionario_id 
		JOIN pessoa p_func ON p_func.id = dependente.funcionario_id
		WHERE p_func.nome = nome_func;

		SELECT p_dep.id INTO id_dep FROM Pessoa p_dep
		WHERE p_dep.nome = nome_dep;

		INSERT INTO Dependente(pessoa_id,funcionario_id,grau_parentesco)
			VALUES(id_dep,id_func,'F');

		SELECT count(*) INTO total_dep FROM dependente
		JOIN funcionario ON funcionario.pessoa_id = dependente.funcionario_id 
		JOIN pessoa p_dep ON p_dep.id = dependente.pessoa_id
		JOIN pessoa p_func ON p_func.id = dependente.funcionario_id
		WHERE p_func.nome = nome_func
		GROUP BY p_func.nome;

		RETURN total_dep;
	ELSE
        RAISE '% não é funcionário(a)',nome_func;		
    END IF;
END;
$$
LANGUAGE plpgsql;
SELECT inserir_dep('Joana Dias', 'Giovana Dias', 'F');
SELECT inserir_dep('Carla Ferreira', 'Fernando Souza', 'M');
SELECT inserir_dep('Jose Freitas','Yasmim Freitas','F');
-- 9. Retorne uma tabela que contenha, para todos os funcionários casados ou com
-- união estável: seus nomes, o nome do cônjuge, e dados completos da certidão
-- (incluindo cartório e cidade que está localizado);
CREATE OR REPLACE FUNCTION estado_civil_funcionarios()
RETURNS TABLE(nome_funcionario varchar(60), nome_conjuge varchar(60), tipo_certidao char(2), data_evento timestamp, num_livro SMALLINT, num_folha SMALLINT, num_termo INT, cartorio varchar(50), cidade varchar(50))
AS
$$
BEGIN
	if(SELECT count(*) FROM Conjuge WHERE conjuge.tipo_certidao = 'CA' OR conjuge.tipo_certidao = 'UE') > 0 THEN
		RETURN QUERY 
			SELECT p_func.nome, p_conj.nome, conjuge.tipo_certidao, conjuge.data_evento, conjuge.numero_livro, conjuge.numero_folha, conjuge.numero_termo, cartorio.nome_cartorio, cidade.nome
			FROM Conjuge
			JOIN Pessoa p_conj ON p_conj.id = conjuge.pessoa_id 
			JOIN Dependente ON dependente.pessoa_id = Conjuge.pessoa_id
			JOIN Pessoa p_func ON p_func.id = dependente.funcionario_id
			JOIN Cartorio ON cartorio.id = conjuge.cartorio_id
			JOIN Cidade ON cidade.codigo = Cartorio.cidade_id;	
    END IF;
END;
$$
LANGUAGE plpgsql;
SELECT estado_civil_funcionarios();
SELECT nome_funcionario, nome_conjuge FROM estado_civil_funcionarios();
SELECT tipo_certidao, data_evento FROM estado_civil_funcionarios();
-- 10.Receba o nome completo de duas pessoas e um código de especialidade médica.
-- Faça as devidas validações e se possível crie um atendimento médico, onde a
-- primeira pessoa é o paciente e a segunda é o médico. Utilize o código de
-- especialidade médica informado e a data/hora atual. Retorne o código do
-- atendimento médico cadastrado
CREATE OR REPLACE FUNCTION novo_atendimento(nome_paciente varchar(60), nome_medico varchar(60), cod_esp varchar(12))
RETURNS integer AS
$$
DECLARE nome_med varchar(60);
DECLARE nome_pac varchar(60);
DECLARE pac_tipo_plano_id SMALLINT;
DECLARE pac_id INT;
DECLARE med_id INT;
DECLARE esp_cod varchar(12);
DECLARE id_atendimento INT;
BEGIN
	SELECT p_med.nome INTO nome_med FROM medico_especialidade 
	JOIN medico ON medico.id = medico_especialidade.medico_id
	JOIN pessoa p_med ON p_med.id = medico.pessoa_id
	JOIN especialidade_medica ON especialidade_medica.codigo = medico_especialidade.codigo_especialidade 
	WHERE p_med.nome = nome_medico AND especialidade_medica.codigo = cod_esp;
	
	SELECT p_pac.nome INTO nome_pac FROM Pessoa p_pac
	WHERE p_pac.nome =  nome_paciente;
	
	if(nome_med = nome_medico AND nome_pac = nome_paciente) THEN
		SELECT p_pac.tipo_plano_id, p_pac.id INTO pac_tipo_plano_id, pac_id FROM Pessoa p_pac
		WHERE p_pac.nome =  nome_paciente;
		
		SELECT medico_id, codigo_especialidade INTO med_id, esp_cod FROM Medico_especialidade
		JOIN medico ON medico.id = medico_especialidade.medico_id
		JOIN pessoa p_med ON p_med.id = medico.pessoa_id
		WHERE p_med.nome = nome_medico;

		SELECT INTO id_atendimento round(CAST (random()*200 AS NUMERIC),0);

		INSERT INTO Atendimento_medico(id,tipo_plano_id,paciente_id,medico_id,especialidade_codigo,data_hora)
			VALUES(id_atendimento,pac_tipo_plano_id,pac_id,med_id,esp_cod,current_timestamp);
		RETURN id_atendimento;
	ELSE
        RAISE 'Nome(s) inválido(s)! Verifique-os e execute novamente';
    END IF;
END;
$$
LANGUAGE plpgsql;

SELECT novo_atendimento('Felipe Melo','Jordana Oliveira','FAMILIA');
SELECT novo_atendimento('Jose Silva','Melissa Washington','CARDIO');
